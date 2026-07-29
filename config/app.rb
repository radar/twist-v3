# frozen_string_literal: true

require "hanami"
require "default_timestamps"

module Twist
  class App < Hanami::App
    config.actions.content_security_policy[:font_src] = "'self' https://fonts.gstatic.com"

    config.base_url = settings.base_url

    config.actions.sessions = :cookie, {
      key: "twist.session",
      secret: settings.session_secret,
      expire_after: 60*60*24*365
    }

    config.middleware.use Rack::Static, urls: ["/assets", "/uploads"], root: "public"

  end
end
