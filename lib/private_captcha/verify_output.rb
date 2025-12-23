# frozen_string_literal: true

module PrivateCaptcha
  # VerifyOutput represents the result of a captcha verification
  class VerifyOutput
    VERIFY_NO_ERROR = 0
    VERIFY_ERROR_OTHER = 1
    DUPLICATE_SOLUTIONS_ERROR = 2
    INVALID_SOLUTION_ERROR = 3
    PARSE_RESPONSE_ERROR = 4
    PUZZLE_EXPIRED_ERROR = 5
    INVALID_PROPERTY_ERROR = 6
    WRONG_OWNER_ERROR = 7
    VERIFIED_BEFORE_ERROR = 8
    MAINTENANCE_MODE_ERROR = 9
    TEST_PROPERTY_ERROR = 10
    INTEGRITY_ERROR = 11
    ORG_SCOPE_ERROR = 12
    VERIFY_CODES_COUNT = 13

    ERROR_MESSAGES = {
      VERIFY_NO_ERROR => '',
      VERIFY_ERROR_OTHER => 'error-other',
      DUPLICATE_SOLUTIONS_ERROR => 'solution-duplicates',
      INVALID_SOLUTION_ERROR => 'solution-invalid',
      PARSE_RESPONSE_ERROR => 'solution-bad-format',
      PUZZLE_EXPIRED_ERROR => 'puzzle-expired',
      INVALID_PROPERTY_ERROR => 'property-invalid',
      WRONG_OWNER_ERROR => 'property-owner-mismatch',
      VERIFIED_BEFORE_ERROR => 'solution-verified-before',
      MAINTENANCE_MODE_ERROR => 'maintenance-mode',
      TEST_PROPERTY_ERROR => 'property-test',
      INTEGRITY_ERROR => 'integrity-error'
      ORG_SCOPE_ERROR => 'org-scope-error'
    }.freeze

    attr_accessor :success, :code, :origin, :timestamp
    attr_reader :trace_id, :attempt

    def initialize(success: false, code: VERIFY_NO_ERROR, origin: nil, timestamp: nil, trace_id: nil, attempt: 0)
      @success = success
      @code = code
      @origin = origin
      @timestamp = timestamp
      @trace_id = trace_id
      @attempt = attempt
    end

    def ok?
      @success == true && @code == VERIFY_NO_ERROR
    end

    def error_message
      ERROR_MESSAGES.fetch(@code, 'error')
    end

    def self.from_json(json_data, trace_id: nil, attempt: 0)
      new(
        success: json_data['success'],
        code: json_data['code'] || VERIFY_NO_ERROR,
        origin: json_data['origin'],
        timestamp: json_data['timestamp'],
        trace_id: trace_id,
        attempt: attempt
      )
    end
  end
end
