# frozen_string_literal: true

source "https://rubygems.org"

gem "hanami", "~> 3.0.0"
gem "hanami-assets", "~> 3.0.0"
gem "hanami-action", "~> 3.0.0"
gem "hanami-db", "~> 3.0.0"
gem "hanami-mailer", "~> 3.0.0"
gem "hanami-router", "~> 3.0.0"
gem "hanami-view", "~> 3.0.0"

gem "dry-types", "~> 1.7"
gem "dry-operation"
gem "dry-validation", "~> 1.11"
gem "puma"
gem "rake"
gem "pg"
gem "dotiw"
gem "redcarpet"
gem "bcrypt"
gem "sidekiq"
gem "rugged"
gem "asciidoctor"
gem "babosa"
gem "nokogiri"
gem "rouge"
gem "shrine"
gem "aws-sdk-s3"

group :development do
  gem "hanami-webconsole", "~> 2.2"
end

group :development, :test do
  gem "dotenv"
  gem "pry"
end

group :cli, :development do
  gem "hanami-reloader", "~> 2.2"
end

group :cli, :development, :test do
  gem "hanami-rspec", "~> 2.2"
end

group :test do
  # Database
  gem "database_cleaner-sequel"

  # Web integration
  gem "capybara"
  gem "rack-test"
end
