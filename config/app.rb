# frozen_string_literal: true

require "hanami"
require "default_timestamps"

module Twist
  class App < Hanami::App
    config.actions.content_security_policy[:font_src] = "'self' https://fonts.gstatic.com"

    config.actions.sessions = :cookie, {
      key: "twist.session",
      secret: settings.session_secret,
      expire_after: 60*60*24*365
    }

  end
end
