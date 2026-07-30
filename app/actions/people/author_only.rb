# frozen_string_literal: true

module Twist
  module Actions
    module People
      # Shared policy for the book's people panel. Requires a `book_repo` dependency.
      module AuthorOnly
        private

        # Returns the book when the current user authors it, otherwise redirects
        # to the book and returns nil so the caller can bail out.
        def authored_book(request, response)
          book = book_repo.find_by_permalink(request.params[:book_permalink])

          return book if book_repo.author?(book:, user: response[:current_user])

          request.flash[:error] = "Only this book's authors can manage who has access to it."
          response.redirect_to routes.path(:book, permalink: book.permalink)
          nil
        end
      end
    end
  end
end
