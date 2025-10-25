PC_API_KEY ?=

install:
	bundle install

update:
	bundle update

test:
	@PC_API_KEY=$(PC_API_KEY) bundle exec rake test

lint:
	bundle exec rubocop

lint-fix:
	bundle exec rubocop -a

security:
	bundle exec bundle-audit check --update

.PHONY: install update test lint lint-fix security
