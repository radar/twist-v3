# frozen_string_literal: true

require "hanami"
require 'vite_hanami'

module Twist
  class App < Hanami::App
    config.actions.content_security_policy[:font_src] = "'self' https://fonts.gstatic.com"

  end
end
