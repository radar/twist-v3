# frozen_string_literal: true

module Twist
  module Actions
    module People
      class Index < Twist::Action
        include Deps["repos.book_repo"]
        include AuthorOnly

        before :authenticate!
        before :ensure_authenticated!

        def handle(request, response)
          book = authored_book(request, response)
          return unless book

          response.render view, book: book, current_user: response[:current_user]
        end
      end
    end
  end
end
