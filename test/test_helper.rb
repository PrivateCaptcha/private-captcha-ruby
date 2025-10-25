# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'private_captcha'
require 'rack'
require 'minitest/autorun'
require 'net/http'
require 'base64'
