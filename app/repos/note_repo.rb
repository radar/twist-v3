# frozen_string_literal: true

module Twist
  module Repos
    class NoteRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def by_element(element)
        notes.by_element(element.id).to_a
      end

      def find_by_book_and_id(book, id)
        book_notes.where(book_id: book.id, id: id).first
      end

      def close!(id)
        notes.where(id: id).update(state: 'closed')
      end

      def open!(id)
        notes.where(id: id).update(state: 'open')
      end

      def update(id, data)
        notes
          .where(id: id)
          .changeset(:update, data)
          .map(:add_timestamps)
          .commit
      end
    end
  end
end
