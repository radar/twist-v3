# frozen_string_literal: true

module Twist
  module Views
    module Invites
      class Show < Twist::View
        include Deps["repos.user_repo"]

        expose :invite
        expose :books

        expose :inviter do |invite|
          user_repo.find(invite.invited_by_id)
        end
      end
    end
  end
end
