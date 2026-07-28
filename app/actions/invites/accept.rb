# frozen_string_literal: true

module Twist
  module Actions
    module Invites
      class Accept < Twist::Action
        include Deps["repos.book_repo", "repos.invite_repo"]

        params do
          required(:token).filled(:str?)

          required(:user).schema do
            required(:name).filled(:str?)
            required(:password).filled(:str?, min_size?: 8)
          end
        end

        def handle(request, response)
          invite = invite_repo.find_pending_by_token(request.params[:token])

          unless invite
            request.flash[:error] = "That invite is no longer valid."
            response.redirect_to routes.path(:login)
            return
          end

          unless request.params.valid?
            request.flash[:error] = "Please provide your name and a password of at least 8 characters."
            response.redirect_to routes.path(:invite, token: invite.token)
            return
          end

          user = user_repo.find_by_email(invite.email) || create_user(request, invite)

          invite_repo.books_for(invite).each do |book|
            next if book_repo.permitted?(book: book, user: user)

            book_repo.grant_permission(book: book, user: user)
          end

          invite_repo.accept!(invite)

          request.session[:user_id] = user.id
          request.flash[:success] = "Welcome to Twist, #{user.name}!"
          response.redirect_to routes.path(:root)
        end

        private

        def create_user(request, invite)
          user_repo.create(
            email: invite.email,
            name: request.params[:user][:name],
            password: request.params[:user][:password]
          )
        end
      end
    end
  end
end
