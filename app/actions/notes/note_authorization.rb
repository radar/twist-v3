# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      # Shared policy for note actions. Requires a `book_repo` dependency.
      module NoteAuthorization
        private

        # Authors can edit any note on their book; anyone else only their own notes.
        def can_edit_note?(book:, note:, user:)
          return false if user.nil? || note.nil?

          note.user_id == user.id || book_repo.author?(book:, user:)
        end

        # Replying is deliberately more open than editing: anyone with access to
        # the book can comment on any note on it, so that authors and readers can
        # hold a conversation in the thread.
        def can_comment_on_note?(book:, user:)
          return false if user.nil? || book.nil?

          book_repo.permitted?(book:, user:)
        end
      end
    end
  end
end
