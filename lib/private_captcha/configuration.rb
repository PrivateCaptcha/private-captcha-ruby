# frozen_string_literal: true

module PrivateCaptcha
  # Configuration holds the settings for the Private Captcha client
  class Configuration
    GLOBAL_DOMAIN = 'api.privatecaptcha.com'
    EU_DOMAIN = 'api.eu.privatecaptcha.com'
    DEFAULT_FORM_FIELD = 'private-captcha-solution'
    DEFAULT_FAILED_STATUS_CODE = 403

    attr_accessor :domain, :api_key, :form_field, :failed_status_code,
                  :max_backoff_seconds, :attempts, :logger

    def initialize
      @domain = GLOBAL_DOMAIN
      @api_key = nil
      @form_field = DEFAULT_FORM_FIELD
      @failed_status_code = DEFAULT_FAILED_STATUS_CODE
      @max_backoff_seconds = 20
      @attempts = 5
      @logger = nil
    end
  end
end
