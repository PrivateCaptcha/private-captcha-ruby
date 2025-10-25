# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

desc 'Run RuboCop'
task :lint do
  sh 'bundle exec rubocop'
end

desc 'Run RuboCop with auto-correct'
task :'lint-fix' do
  sh 'bundle exec rubocop -a'
end

desc 'Run security audit'
task :security do
  sh 'bundle exec bundle-audit check --update'
end

desc 'Run all checks (lint, security, tests)'
task all: %i[lint security test]

task default: :all

desc 'Display usage information'
task :usage do
  puts <<~USAGE
    Private Captcha Ruby Client - Rake Tasks

    Usage:
      rake test                    # Run all tests
      rake lint                    # Run RuboCop linter
      rake lint-fix                # Run RuboCop with auto-correct
      rake security                # Run security audit
      rake all                     # Run all checks (lint, security, tests)
      PC_API_KEY=xxx rake test     # Run tests with API key

    Environment Variables:
      PC_API_KEY    API key for Private Captcha (required for tests)
  USAGE
end
