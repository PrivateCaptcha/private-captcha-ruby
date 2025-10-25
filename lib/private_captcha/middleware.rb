# frozen_string_literal: true

require 'rack'

module PrivateCaptcha
  # Middleware provides Rack middleware for automatic captcha verification
  class Middleware
    # rubocop:disable Metrics/AbcSize
    def initialize(app, api_key:, **options)
      @app = app
      @client = Client.new do |config|
        config.api_key = api_key
        config.domain = options[:domain] if options[:domain]
        config.form_field = options[:form_field] if options[:form_field]
        config.failed_status_code = options[:failed_status_code] if options[:failed_status_code]
        config.max_backoff_seconds = options[:max_backoff_seconds] if options[:max_backoff_seconds]
        config.attempts = options[:attempts] if options[:attempts]
        config.logger = options[:logger] if options[:logger]
      end
    end
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/MethodLength
    def call(env)
      request = Rack::Request.new(env)

      begin
        @client.verify_request(request)
      rescue Error
        return [
          @client.config.failed_status_code,
          { 'Content-Type' => 'text/plain' },
          [Rack::Utils::HTTP_STATUS_CODES[@client.config.failed_status_code]]
        ]
      end

      @app.call(env)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
