# auto_register: false
# frozen_string_literal: true
#
require 'dotiw'

module Twist
  module Views
    module Helpers
      include DOTIW::Methods
      def book_path(book)
        routes.path(:book, permalink: book.permalink)
      end

      def chapter_path(book, chapter)
        routes.path(:chapter, book_permalink: book.permalink, permalink: chapter.permalink)
      end
    end
  end
end
