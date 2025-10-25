# frozen_string_literal: true

module PrivateCaptcha
  class Error < StandardError; end

  # EmptyAPIKeyError is raised when the API key is not provided or is empty
  class EmptyAPIKeyError < Error
    def initialize(msg = 'API key is empty')
      super
    end
  end

  # EmptySolutionError is raised when the solution is not provided or is empty
  class EmptySolutionError < Error
    def initialize(msg = 'solution is empty')
      super
    end
  end

  # HTTPError is raised when an HTTP error occurs during verification
  class HTTPError < Error
    attr_reader :status_code, :seconds

    def initialize(status_code, seconds = nil)
      @status_code = status_code
      @seconds = seconds
      super("HTTP error #{status_code}")
    end
  end

  # RetriableError wraps errors that can be retried
  class RetriableError < Error
    attr_reader :original_error

    def initialize(error)
      @original_error = error
      super(error.message)
    end
  end
end
