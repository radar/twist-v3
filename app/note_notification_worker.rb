# frozen_string_literal: true

module Twist
  # Emails a book's authors when a reader leaves a note. Runs in the background
  # so a slow or broken mail server can't take the note form down with it.
  class NoteNotificationWorker
    include Sidekiq::Worker

    include Deps[
      "repos.book_repo",
      "repos.note_repo",
      mailer: "mailers.note_notification"
    ]

    def perform(note_id)
      note = note_repo.find_with_context(note_id)
      return if note.nil?

      book = book_repo.by_id(note.book_id)
      return if book.nil?

      recipients_for(book, note).each do |recipient|
        mailer.deliver(
          recipient: recipient,
          note: note,
          book: book,
          chapter: note.element.chapter,
          author: note.user
        )
      end
    end

    private

    # Authors are the ones who can act on a note, so they're the ones told about
    # it. Never the person who just wrote it.
    def recipients_for(book, note)
      book_repo
        .authors_for(book)
        .reject { |author| author.id == note.user_id }
        .select { |author| author.email.to_s.include?("@") }
    end
  end
end
