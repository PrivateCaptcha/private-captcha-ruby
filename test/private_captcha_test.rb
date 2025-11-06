# frozen_string_literal: true

require_relative 'test_helper'

class PrivateCaptchaTest < Minitest::Test
  SOLUTIONS_COUNT = 16
  SOLUTION_LENGTH = 8

  @test_puzzle_data = nil
  @test_puzzle_mutex = Mutex.new

  class << self
    attr_accessor :test_puzzle_data, :test_puzzle_mutex
  end

  def setup
    @logger = Logger.new($stdout)
    @logger.level = Logger::DEBUG
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def fetch_test_puzzle
    self.class.test_puzzle_mutex.synchronize do
      return self.class.test_puzzle_data if self.class.test_puzzle_data

      uri = URI('https://api.privatecaptcha.com/puzzle?sitekey=aaaaaaaabbbbccccddddeeeeeeeeeeee')
      request = Net::HTTP::Get.new(uri)
      request['Origin'] = 'not.empty'

      @logger.debug('About to send puzzle request')

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      raise "Failed to fetch puzzle: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      self.class.test_puzzle_data = response.body
      @logger.debug("Received puzzle: #{self.class.test_puzzle_data.length} bytes")

      self.class.test_puzzle_data
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def test_stub_puzzle
    puzzle = fetch_test_puzzle

    client = PrivateCaptcha::Client.new do |config|
      config.api_key = ENV.fetch('PC_API_KEY', nil)
      config.logger = @logger
    end

    empty_solutions_bytes = "\x00" * (SOLUTIONS_COUNT * SOLUTION_LENGTH)
    solutions_str = Base64.strict_encode64(empty_solutions_bytes)
    payload = "#{solutions_str}.#{puzzle}"

    output = client.verify(payload)

    assert output.success
    assert_equal PrivateCaptcha::VerifyOutput::TEST_PROPERTY_ERROR, output.code
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def test_verify_error
    puzzle = fetch_test_puzzle

    client = PrivateCaptcha::Client.new do |config|
      config.api_key = ENV.fetch('PC_API_KEY', nil)
      config.logger = @logger
    end

    # Use half the required solution length to trigger error
    empty_solutions_bytes = "\x00" * (SOLUTIONS_COUNT * SOLUTION_LENGTH / 2)
    solutions_str = Base64.strict_encode64(empty_solutions_bytes)
    payload = "#{solutions_str}.#{puzzle}"

    error = assert_raises(PrivateCaptcha::HTTPError) do
      client.verify(payload)
    end

    assert_equal 400, error.status_code
  end
  # rubocop:enable Metrics/MethodLength

  def test_verify_empty_solution
    client = PrivateCaptcha::Client.new do |config|
      config.api_key = ENV.fetch('PC_API_KEY', nil)
      config.logger = @logger
    end

    error = assert_raises(PrivateCaptcha::EmptySolutionError) do
      client.verify('')
    end

    assert_equal 'solution is empty', error.message
  end

  # rubocop:disable Metrics/MethodLength
  def test_retry_backoff
    client = PrivateCaptcha::Client.new do |config|
      config.api_key = ENV.fetch('PC_API_KEY', nil)
      config.domain = 'does-not-exist.qwerty12345-asdfjkl.net'
      config.logger = @logger
      config.attempts = 4
      config.max_backoff_seconds = 1
    end

    error = assert_raises(PrivateCaptcha::VerificationFailedError) do
      client.verify('asdf')
    end

    # Should have failed after 4 attempts
    assert_equal 4, error.attempts
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def test_custom_form_field
    puzzle = fetch_test_puzzle

    custom_field_name = 'my-custom-captcha-field'
    client = PrivateCaptcha::Client.new do |config|
      config.api_key = ENV.fetch('PC_API_KEY', nil)
      config.form_field = custom_field_name
      config.logger = @logger
    end

    # Create a valid test payload (using empty solutions for test property)
    empty_solutions_bytes = "\x00" * (SOLUTIONS_COUNT * SOLUTION_LENGTH)
    solutions_str = Base64.strict_encode64(empty_solutions_bytes)
    payload = "#{solutions_str}.#{puzzle}"

    # Create mock Rack request with custom field name
    env = {
      'REQUEST_METHOD' => 'POST',
      'rack.input' => StringIO.new
    }
    request = Rack::Request.new(env)
    request.params[custom_field_name] = payload

    # Verify that VerifyRequest reads from the custom form field
    output = client.verify_request(request)

    assert output.success

    # Also test that it doesn't work with the default field name
    env2 = {
      'REQUEST_METHOD' => 'POST',
      'rack.input' => StringIO.new
    }
    default_request = Rack::Request.new(env2)
    default_request.params[PrivateCaptcha::Configuration::DEFAULT_FORM_FIELD] = payload

    # This should fail because the client is configured to use the custom field
    error = assert_raises(PrivateCaptcha::EmptySolutionError) do
      client.verify_request(default_request)
    end

    assert_equal 'solution is empty', error.message
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def test_empty_api_key
    error = assert_raises(PrivateCaptcha::EmptyAPIKeyError) do
      PrivateCaptcha::Client.new do |config|
        config.api_key = ''
      end
    end

    assert_equal 'API key is empty', error.message
  end

  # rubocop:disable Metrics/MethodLength
  def test_custom_failed_status_code
    # Create a simple app that should be protected by the middleware
    app = lambda do |_env|
      [200, { 'Content-Type' => 'text/plain' }, ['success']]
    end

    # Wrap with the captcha middleware with custom failed status code
    custom_status_code = 418 # I'm a teapot
    middleware = PrivateCaptcha::Middleware.new(app, api_key: ENV.fetch('PC_API_KEY', nil),
                                                     failed_status_code: custom_status_code, logger: @logger)

    # Create request with empty captcha solution (should fail)
    env = {
      'REQUEST_METHOD' => 'POST',
      'rack.input' => StringIO.new,
      'QUERY_STRING' => ''
    }

    status, _headers, _body = middleware.call(env)

    assert_equal custom_status_code, status
  end
  # rubocop:enable Metrics/MethodLength

  def test_verify_output_error_message
    output = PrivateCaptcha::VerifyOutput.new(
      success: false,
      code: PrivateCaptcha::VerifyOutput::INVALID_SOLUTION_ERROR
    )

    assert_equal 'solution-invalid', output.error_message
  end

  # rubocop:disable Metrics/MethodLength
  def test_verify_output_from_json
    json_data = {
      'success' => true,
      'code' => 0,
      'origin' => 'example.com',
      'timestamp' => '2024-01-01T00:00:00Z'
    }

    output = PrivateCaptcha::VerifyOutput.from_json(json_data, trace_id: 'test-123', attempt: 2)

    assert output.success
    assert_equal 0, output.code
    assert_equal 'example.com', output.origin
    assert_equal '2024-01-01T00:00:00Z', output.timestamp
    assert_equal 'test-123', output.trace_id
    assert_equal 2, output.attempt
  end
  # rubocop:enable Metrics/MethodLength

  def test_configuration_defaults
    config = PrivateCaptcha::Configuration.new

    assert_equal PrivateCaptcha::Configuration::GLOBAL_DOMAIN, config.domain
    assert_equal PrivateCaptcha::Configuration::DEFAULT_FORM_FIELD, config.form_field
    assert_equal PrivateCaptcha::Configuration::DEFAULT_FAILED_STATUS_CODE, config.failed_status_code
    assert_equal 20, config.max_backoff_seconds
    assert_equal 5, config.attempts
    assert_nil config.api_key
    assert_nil config.logger
  end

  def test_normalize_domain
    client = PrivateCaptcha::Client.new do |config|
      config.api_key = 'test-key'
      config.domain = 'https://custom.domain.com/'
    end

    assert_equal 'custom.domain.com', client.config.domain
  end

  def test_http_error_attributes
    error = PrivateCaptcha::HTTPError.new(429, 60)

    assert_equal 429, error.status_code
    assert_equal 60, error.seconds
    assert_equal 'HTTP error 429', error.message
  end
end
