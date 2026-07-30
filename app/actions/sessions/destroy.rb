# frozen_string_literal: true

module Twist
  module Actions
    module Sessions
      class Destroy < Twist::Action
        def handle(request, response)
          request.session[:user_id] = nil
          request.flash[:success] = "You have been signed out."
          response.redirect_to routes.path(:login)
        end
      end
    end
  end
end
