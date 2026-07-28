# frozen_string_literal: true

module Twist
  module Actions
    module Invites
      class Show < Twist::Action
        include Deps["repos.invite_repo"]

        def handle(request, response)
          invite = invite_repo.find_pending_by_token(request.params[:token])

          unless invite
            request.flash[:error] = "That invite is no longer valid."
            response.redirect_to routes.path(:login)
            return
          end

          response.render view, invite: invite, books: invite_repo.books_for(invite)
        end
      end
    end
  end
end
