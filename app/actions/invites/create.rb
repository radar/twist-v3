# frozen_string_literal: true

module Twist
  module Actions
    module Invites
      class Create < Twist::Action
        include Deps[
          "repos.book_repo",
          "repos.invite_repo",
          invite_mailer: "mailers.invite",
        ]

        before :authenticate!
        before :ensure_authenticated!

        params do
          required(:invite).schema do
            required(:email).filled(:str?, format?: /@/)
            optional(:book_ids).array(:integer)
          end
        end

        def handle(request, response)
          unless request.params.valid?
            request.flash[:error] = "Please provide a valid email address."
            response.redirect_to routes.path(:new_invite)
            return
          end

          inviter = response[:current_user]
          email = request.params[:invite][:email]

          if user_repo.find_by_email(email)
            request.flash[:error] = "#{email} already has a Twist account."
            response.redirect_to routes.path(:new_invite)
            return
          end

          invite = invite_repo.create_for(
            email: email,
            invited_by: inviter,
            book_ids: authorized_book_ids(request, inviter)
          )

          invite_mailer.deliver(
            invite: invite,
            inviter: inviter,
            books: invite_repo.books_for(invite)
          )

          request.flash[:success] = "Invite sent to #{invite.email}."
          response.redirect_to routes.path(:new_invite)
        end

        private

        # Only books the current user is an author on can be granted, regardless of what was
        # submitted.
        def authorized_book_ids(request, inviter)
          submitted = request.params[:invite][:book_ids] || []
          submitted & book_repo.authored_by(inviter).map(&:id)
        end
      end
    end
  end
end
