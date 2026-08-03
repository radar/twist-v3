# frozen_string_literal: true

module Twist
  # Emails everyone in a note's conversation when someone replies. Runs in the
  # background so a slow or broken mail server can't take the reply form down
  # with it.
  class CommentNotificationWorker
    include Sidekiq::Worker

    include Deps[
      "repos.book_repo",
      "repos.comment_repo",
      "repos.note_repo",
      mailer: "mailers.comment_notification"
    ]

    def perform(comment_id)
      comment = comment_repo.by_id(comment_id)
      return if comment.nil?

      note = note_repo.find_with_context(comment.note_id)
      return if note.nil?

      book = book_repo.by_id(note.book_id)
      return if book.nil?

      recipients_for(book, note, comment).each do |recipient|
        mailer.deliver(
          recipient: recipient,
          comment: comment,
          note: note,
          book: book,
          chapter: note.element.chapter,
          author: comment.user
        )
      end
    end

    private

    # Everyone with a stake in the thread: whoever wrote the note, whoever has
    # already replied to it, and the book's authors. Never the person who just
    # replied, and only once each however many of those they are.
    def recipients_for(book, note, comment)
      people = [note.user] +
        comment_repo.participants_for(note.id) +
        book_repo.authors_for(book)

      people
        .compact
        .uniq(&:id)
        .reject { |person| person.id == comment.user_id }
        .select { |person| person.email.to_s.include?("@") }
    end
  end
end
