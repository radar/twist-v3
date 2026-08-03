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
      response[:current_user] = user_repo.find(request.session[:user_id])
    end

    # Forms that live on more than one page send a `return_to` so we can put the
    # reader back where they were: a note closed from the book's notes list
    # belongs on that list, not on the element's own page. Only same-site paths
    # are honoured, otherwise the field is an open redirect.
    def return_path(request, fallback:)
      path = request.params[:return_to]

      return fallback unless path.is_a?(String)
      return fallback unless path.start_with?("/")
      return fallback if path.start_with?("//", "/\\")

      path
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
