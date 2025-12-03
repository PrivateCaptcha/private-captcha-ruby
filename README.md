# private-captcha-ruby

[![Gem Version](https://badge.fury.io/rb/private_captcha.svg)](https://badge.fury.io/rb/private_captcha)
 ![CI](https://github.com/PrivateCaptcha/private-captcha-ruby/actions/workflows/ci.yaml/badge.svg)

Ruby client for server-side verification of Private Captcha solutions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'private_captcha'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install private_captcha
```

## Quick Start

```ruby
require 'private_captcha'

# Initialize the client with your API key
client = PrivateCaptcha::Client.new do |config|
  config.api_key = 'your-api-key-here'
end

# Verify a captcha solution
begin
  result = client.verify('user-solution-from-frontend')
  if result.ok?
    puts 'Captcha verified successfully!'
  else
    puts "Verification failed: #{result.error_message}"
  end
rescue PrivateCaptcha::Error => e
  puts "Error: #{e.message}"
end
```

## Usage

### Web Framework Integration

#### Sinatra Example

```ruby
require 'sinatra'
require 'private_captcha'

client = PrivateCaptcha::Client.new do |config|
  config.api_key = 'your-api-key'
end

post '/submit' do
  begin
    # Verify captcha from form data
    client.verify_request(request)

    # Process your form data here
    'Form submitted successfully!'
  rescue PrivateCaptcha::Error
    status 400
    'Captcha verification failed'
  end
end
```

#### Rails Example

```ruby
class FormsController < ApplicationController
  def submit
    client = PrivateCaptcha::Client.new do |config|
      config.api_key = 'your-api-key'
    end

    begin
      client.verify_request(request)
      # Process form data
      render plain: 'Success!'
    rescue PrivateCaptcha::Error
      render plain: 'Captcha failed', status: :bad_request
    end
  end
end
```

#### Rack Middleware

```ruby
require 'private_captcha'

use PrivateCaptcha::Middleware,
  api_key: 'your-api-key',
  failed_status_code: 403
```

## Configuration

### Client Options

```ruby
require 'private_captcha'

client = PrivateCaptcha::Client.new do |config|
  config.api_key = 'your-api-key'
  config.domain = PrivateCaptcha::Configuration::EU_DOMAIN  # replace domain for self-hosting or EU isolation
  config.form_field = 'private-captcha-solution'            # custom form field name
  config.max_backoff_seconds = 20                           # maximum wait between retries
  config.attempts = 5                                       # number of retry attempts
  config.logger = Logger.new(STDOUT)                        # optional logger
end
```

### Non-standard backend domains

```ruby
require 'private_captcha'

# Use EU domain
eu_client = PrivateCaptcha::Client.new do |config|
  config.api_key = 'your-api-key'
  config.domain = PrivateCaptcha::Configuration::EU_DOMAIN  # api.eu.privatecaptcha.com
end

# Or specify custom domain in case of self-hosting
custom_client = PrivateCaptcha::Client.new do |config|
  config.api_key = 'your-api-key'
  config.domain = 'your-custom-domain.com'
end
```

### Retry Configuration

```ruby
result = client.verify(
  'solution',
  max_backoff_seconds: 15,  # maximum wait between retries
  attempts: 3               # number of retry attempts
)
```

## Requirements

- Ruby 3.0+
- No external dependencies (uses only standard library)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues with this Ruby client, please open an issue on GitHub.
For Private Captcha service questions, visit [privatecaptcha.com](https://privatecaptcha.com).
