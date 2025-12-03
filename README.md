# private-captcha-ruby

[![Gem Version](https://badge.fury.io/rb/private_captcha.svg)](https://badge.fury.io/rb/private_captcha)
 ![CI](https://github.com/PrivateCaptcha/private-captcha-ruby/actions/workflows/ci.yaml/badge.svg)

Ruby client for server-side verification of Private Captcha solutions.

<mark>Please check the [official documentation](https://docs.privatecaptcha.com/docs/integrations/ruby/) for the in-depth and up-to-date information.</mark>

## Quick Start

- Install gem `private_captcha`
  ```bash
  gem install private_captcha
  ```
- Instantiate the client and call `verify()` method to check the captcha solution
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
- Integrate using Rack middleware or use with Sinatra or Rails with `client.verify_request()` helper

## Requirements

- Ruby 3.0+
- No external dependencies (uses only standard library)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues with this Ruby client, please open an issue on GitHub.
For Private Captcha service questions, visit [privatecaptcha.com](https://privatecaptcha.com).
