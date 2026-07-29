# frozen_string_literal: true

module Twist
  class Settings < Hanami::Settings
    setting :session_secret, constructor: Types::String

    # Used to build absolute URLs in emails.
    setting :base_url, default: "http://localhost:2300", constructor: Types::String

    # From address for all outbound email.
    setting :mail_from, default: "noreply@twist.dev", constructor: Types::String

    setting :sentry_dsn, default: ENV.fetch("SENTRY_DSN", nil), constructor: Types::String
  end
end
