# frozen_string_literal: true

module Twist
  module Actions
    module Sessions
      class Create < Twist::Action
        include Deps["repos.user_repo"]
        params do
          required(:session).schema do
            required(:email).filled(:str?)
            required(:password).filled(:str?)
          end
        end

        def handle(request, response)
          session_params = request.params[:session]
          user = user_repo.authenticate(session_params[:email], session_params[:password])

          if user
            request.session[:user_id] = user.id
            request.flash[:success] = "Welcome back, #{user.name}!"
            response.redirect_to routes.path(:root)
          else
            request.flash[:error] = "Invalid email or password."
            response.redirect_to routes.path(:login)
          end

        end
      end
    end
  end
end
