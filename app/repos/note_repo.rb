# frozen_string_literal: true

module Twist
  module Repos
    class NoteRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def by_element(element)
        notes.by_element(element.id).to_a
      end

      def open_count_by_commit(commit)
        notes.open_for_commit(commit.id).count
      end

      # => { chapter_id => open note count }
      def open_counts_by_chapter(commit)
        notes
          .open_counts_by_chapter(commit.id)
          .to_a
          .each_with_object({}) { |row, counts| counts[row[:chapter_id]] = row[:open_note_count] }
      end

      def open_by_commit(commit)
        notes.open_by_commit(commit.id).combine(element: [:chapter, :image]).to_a
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
