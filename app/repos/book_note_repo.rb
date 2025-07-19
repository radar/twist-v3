# frozen_string_literal: true

module Twist
  module Repos
    class BookNoteRepo < Twist::DB::Repo
      def count_for_book(book_id)
        by_book(book_id).count
      end

      def by_book(book_id)
        book_notes.where(book_id: book_id)
      end

    end
  end
end
