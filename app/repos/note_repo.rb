# frozen_string_literal: true

module Twist
  module Repos
    class NoteRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      # A note plus everything a notification email needs to describe and link
      # to it. Returns nil when the note has since been deleted.
      def find_with_context(id)
        notes.by_pk(id).combine(:user, element: :chapter).one
      end

      def by_element(element)
        notes.by_element(element.id).to_a
      end

      # => { chapter_id => open note count }
      def open_counts_by_chapter(commit)
        notes
          .open_counts_by_chapter(commit.id)
          .to_a
          .each_with_object({}) { |row, counts| counts[row[:chapter_id]] = row[:open_note_count] }
      end

      def open_count_by_book(book)
        notes.open_for_book(book.id).count
      end

      def closed_count_by_book(book)
        notes.closed_for_book(book.id).count
      end

      def open_by_book(book)
        notes.open_by_book(book.id).combine(element: [:chapter, :image]).to_a
      end

      def closed_by_book(book)
        notes.closed_by_book(book.id).combine(element: [:chapter, :image]).to_a
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
