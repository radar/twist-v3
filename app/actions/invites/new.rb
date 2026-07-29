# frozen_string_literal: true

module Twist
  module Actions
    module Invites
      class New < Twist::Action
        before :authenticate!
        before :ensure_authenticated!

        def handle(request, response)
          response.render view, user: response[:current_user]
        end
      end
    end
  end
end
