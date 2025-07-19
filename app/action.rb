# auto_register: false
# frozen_string_literal: true

require "hanami/action"
require "dry/monads"

module Twist
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]
    include Deps["repos.user_repo"]

    def authenticate!(request, response)
      user = user_repo.find(request.session[:user_id])
      if user
        response[:current_user] = user
      end
    end

    def ensure_authenticated!(request, response)
      unless request.session[:user_id]
        request.flash[:error] = "You must be logged in to perform this action."
        response.redirect_to routes.path(:login)
        halt
      end
    end
  end
end
