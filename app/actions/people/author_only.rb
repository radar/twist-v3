# auto_register: false
# frozen_string_literal: true

module Twist
  module Actions
    module People
      # The book-author policy, worded for the book's people panel.
      module AuthorOnly
        include Twist::Actions::BookAuthorOnly

        private

        def author_only_message
          "Only this book's authors can manage who has access to it."
        end
      end
    end
  end
end
