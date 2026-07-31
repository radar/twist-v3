# auto_register: false
# frozen_string_literal: true

module Twist
  module Actions
    # Shared policy for pages only a book's authors may see. Requires a
    # `book_repo` dependency, and a `:book_permalink` route param.
    module BookAuthorOnly
      private

      # Returns the book when the current user authors it, otherwise redirects
      # to the book and returns nil so the caller can bail out.
      def authored_book(request, response)
        book = book_repo.find_by_permalink(request.params[:book_permalink])

        return book if book_repo.author?(book:, user: response[:current_user])

        request.flash[:error] = author_only_message
        response.redirect_to routes.path(:book, permalink: book.permalink)
        nil
      end

      # Overridden by includers that want to name what is being guarded.
      def author_only_message
        "Only this book's authors can do that."
      end
    end
  end
end
