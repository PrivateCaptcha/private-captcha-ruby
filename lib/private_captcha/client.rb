# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'logger'
require 'timeout'

module PrivateCaptcha
  # Client is the main class for verifying Private Captcha solutions
  class Client # rubocop:disable Metrics/ClassLength
    MIN_BACKOFF_MILLIS = 500

    attr_reader :config

    def initialize
      @config = Configuration.new
      yield(@config) if block_given?

      raise EmptyAPIKeyError if @config.api_key.nil? || @config.api_key.empty?

      @config.domain = normalize_domain(@config.domain)
      @endpoint = URI("https://#{@config.domain}/verify")
      @logger = @config.logger || Logger.new(IO::NULL)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def verify(solution, max_backoff_seconds: nil, attempts: nil)
      raise EmptySolutionError if solution.nil? || solution.empty?

      max_backoff = max_backoff_seconds || @config.max_backoff_seconds
      max_attempts = attempts || @config.attempts

      @logger.debug('About to start verifying solution') do
        "maxAttempts=#{max_attempts} maxBackoff=#{max_backoff} solution_length=#{solution.length}"
      end

      response = nil
      error = nil
      attempt = 0
      trace_id = nil

      max_attempts.times do |i|
        attempt = i + 1

        if i.positive?
          backoff_duration = calculate_backoff(i, max_backoff, error)
          @logger.debug('Failed to send verify request') do
            "attempt=#{attempt} backoff=#{backoff_duration}s error=#{error&.message}"
          end
          sleep(backoff_duration)
        end

        begin
          response = do_verify(solution)
          error = nil
          break
        rescue RetriableError => e
          error = e.original_error
          trace_id = e.trace_id if e.trace_id
        end
      end

      @logger.debug('Finished verifying solution') do
        "attempts=#{attempt} success=#{error.nil?}"
      end

      if error
        @logger.error("Failed to verify solution after #{attempt} attempts")
        raise VerificationFailedError.new("Failed to verify solution after #{attempt} attempts", attempt, trace_id: trace_id)
      end

      response
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def verify_request(request, form_field: nil)
      field = form_field || @config.form_field
      solution = extract_form_value(request, field)

      output = verify(solution)

      raise Error.new("captcha verification failed: #{output.error_message}", trace_id: output.trace_id) unless output.success

      output
    end

    private

    def normalize_domain(domain)
      return Configuration::GLOBAL_DOMAIN if domain.nil? || domain.empty?

      domain = domain.delete_prefix('https://')
      domain = domain.delete_prefix('http://')
      domain.delete_suffix('/')
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def do_verify(solution)
      request = Net::HTTP::Post.new(@endpoint)
      request['X-Api-Key'] = @config.api_key
      request['User-Agent'] = "private-captcha-ruby/#{VERSION}"
      request['Content-Type'] = 'text/plain'
      request.body = solution

      @logger.debug('Sending HTTP request') { "path=#{@endpoint.path} method=POST" }

      response = nil
      trace_id = nil
      begin
        response = Net::HTTP.start(@endpoint.hostname, @endpoint.port, use_ssl: true) do |http|
          http.request(request)
        end
        trace_id = response['X-Trace-ID']
      rescue SocketError, IOError, Timeout::Error, SystemCallError => e
        @logger.debug('Failed to send HTTP request') { "error=#{e.message}" }
        raise RetriableError.new(e, trace_id: trace_id)
      end

      @logger.debug('HTTP request finished') do
        "path=#{@endpoint.path} status=#{response.code}"
      end

      status_code = response.code.to_i

      case status_code
      when 429
        retry_after = parse_retry_after(response['Retry-After'])
        @logger.debug('Rate limited') do
          "retryAfter=#{retry_after} rateLimit=#{response['X-RateLimit-Limit']}"
        end
        raise RetriableError.new(HTTPError.new(status_code, retry_after, trace_id: trace_id), trace_id: trace_id)
      when 500, 502, 503, 504, 408, 425
        raise RetriableError.new(HTTPError.new(status_code, trace_id: trace_id), trace_id: trace_id)
      when 300..599
        raise HTTPError.new(status_code, trace_id: trace_id)
      end

      begin
        json_data = JSON.parse(response.body)
        VerifyOutput.from_json(json_data, trace_id: trace_id)
      rescue JSON::ParserError => e
        @logger.debug('Failed to parse response') { "error=#{e.message}" }
        raise RetriableError.new(e, trace_id: trace_id)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def parse_retry_after(header)
      return nil if header.nil? || header.empty?

      Integer(header)
    rescue ArgumentError
      nil
    end

    def calculate_backoff(attempt, max_backoff, error)
      backoff = (MIN_BACKOFF_MILLIS / 1000.0) * (2**attempt)

      backoff = [backoff, error.seconds].max if error.is_a?(HTTPError) && error.seconds

      [backoff, max_backoff].min
    end

    def extract_form_value(request, field)
      # Support for Rack::Request
      if request.respond_to?(:params)
        request.params[field]
      # Support for Rails ActionDispatch::Request
      elsif request.respond_to?(:[])
        request[field]
      end
    end
  end
end
