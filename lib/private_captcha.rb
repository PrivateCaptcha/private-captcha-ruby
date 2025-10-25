# frozen_string_literal: true

require_relative 'private_captcha/version'
require_relative 'private_captcha/errors'
require_relative 'private_captcha/verify_output'
require_relative 'private_captcha/configuration'
require_relative 'private_captcha/client'
require_relative 'private_captcha/middleware'

# PrivateCaptcha is a Ruby client library for integrating Private Captcha
# verification into your applications. It provides a simple API for verifying
# captcha solutions and can be used as Rack middleware.
module PrivateCaptcha
end
