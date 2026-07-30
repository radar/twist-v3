# frozen_string_literal: true

module Twist
  module Actions
    module People
      class Update < Twist::Action
        include Deps["repos.book_repo"]
        include AuthorOnly

        before :authenticate!
        before :ensure_authenticated!

        params do
          required(:book_permalink).filled(:string)
          required(:user_id).filled(:integer)
          required(:person).schema do
            required(:author).filled(:bool)
          end
        end

        def handle(request, response)
          book = authored_book(request, response)
          return unless book

          people_path = routes.path(:book_people, book_permalink: book.permalink)

          unless request.params.valid?
            request.flash[:error] = "That change could not be applied."
            response.redirect_to people_path
            return
          end

          person = user_repo.find(request.params[:user_id])
          author = request.params[:person][:author]

          unless person && book_repo.permitted?(book:, user: person)
            request.flash[:error] = "That person does not have access to this book."
            response.redirect_to people_path
            return
          end

          if demoting_last_author?(book:, person:, author:)
            request.flash[:error] = "#{book.title} must have at least one author."
            response.redirect_to people_path
            return
          end

          book_repo.set_author(book:, user: person, author:)

          request.flash[:success] =
            if author
              "#{person.name} is now an author on #{book.title}."
            else
              "#{person.name} is no longer an author on #{book.title}."
            end

          response.redirect_to people_path
        end

        private

        def demoting_last_author?(book:, person:, author:)
          return false if author
          return false unless book_repo.author?(book:, user: person)

          book_repo.author_count(book) <= 1
        end
      end
    end
  end
end
