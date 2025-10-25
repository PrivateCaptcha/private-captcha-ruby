# frozen_string_literal: true

require_relative 'lib/private_captcha/version'

Gem::Specification.new do |spec|
  spec.name = 'private_captcha'
  spec.version = PrivateCaptcha::VERSION
  spec.authors = ['Taras Kushnir']
  # spec.email = ["your.email@example.com"]

  spec.summary = 'Ruby client for server-side Private Captcha API'
  spec.description = 'A Ruby library for integrating Private Captcha verification into your applications'
  spec.homepage = 'https://privatecaptcha.com'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/PrivateCaptcha/private-captcha-ruby'
  spec.metadata['rubygems_mfa_required'] = 'true'
  # spec.metadata["changelog_uri"] = "https://github.com/PrivateCaptcha/private-captcha-ruby/"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'rack', '>= 2.0'
end
