# frozen_string_literal: true

module Twist
  module Mailers
    class Invite < Hanami::Mailer
      include Deps["settings", "routes"]

      from { settings.mail_from }
      to { |invite:| invite.email }
      subject { |inviter| "#{inviter.name} has invited you to Twist" }

      expose :invite
      expose :inviter
      expose :books, default: []

      expose :accept_url do |invite:|
        routes.url(:invite, token: invite.token).to_s
      end
    end
  end
end
