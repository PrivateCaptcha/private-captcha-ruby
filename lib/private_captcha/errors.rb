# frozen_string_literal: true

module PrivateCaptcha
  class Error < StandardError
    attr_reader :trace_id

    def initialize(msg = nil, trace_id: nil)
      @trace_id = trace_id
      super(msg)
    end
  end

  # EmptyAPIKeyError is raised when the API key is not provided or is empty
  class EmptyAPIKeyError < Error
    def initialize(msg = 'API key is empty', trace_id: nil)
      super(msg, trace_id: trace_id)
    end
  end

  # EmptySolutionError is raised when the solution is not provided or is empty
  class EmptySolutionError < Error
    def initialize(msg = 'solution is empty', trace_id: nil)
      super(msg, trace_id: trace_id)
    end
  end

  # HTTPError is raised when an HTTP error occurs during verification
  class HTTPError < Error
    attr_reader :status_code, :seconds

    def initialize(status_code, seconds = nil, trace_id: nil)
      @status_code = status_code
      @seconds = seconds
      super("HTTP error #{status_code}", trace_id: trace_id)
    end
  end

  # RetriableError wraps errors that can be retried
  class RetriableError < Error
    attr_reader :original_error

    def initialize(error)
      @original_error = error
      super(error.message)
    end

    def trace_id
      @original_error.respond_to?(:trace_id) ? @original_error.trace_id : nil
    end
  end

  # VerificationFailedError is raised when verification fails after all retry attempts
  class VerificationFailedError < Error
    attr_reader :attempts

    def initialize(message, attempts, trace_id: nil)
      @attempts = attempts
      super(message, trace_id: trace_id)
    end
  end
end
