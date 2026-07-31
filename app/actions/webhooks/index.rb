# frozen_string_literal: true

module Twist
  module Actions
    module Webhooks
      class Index < Twist::Action
        include Deps["repos.book_repo"]
        include Twist::Actions::BookAuthorOnly

        before :authenticate!
        before :ensure_authenticated!

        def handle(request, response)
          book = authored_book(request, response)
          return unless book

          response.render view, book: book
        end

        private

        def author_only_message
          "Only this book's authors can see its webhook setup."
        end
      end
    end
  end
end
