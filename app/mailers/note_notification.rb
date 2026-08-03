# frozen_string_literal: true

module Twist
  module Mailers
    # Tells a book's authors that a reader has left a note on one of their
    # paragraphs. One email per recipient, sent from NoteNotificationWorker.
    class NoteNotification < Hanami::Mailer
      include Deps["settings", "routes"]

      from { settings.mail_from }
      to { |recipient| recipient.email }
      subject { |book, note| "New note on #{book.title}" }

      expose :note
      expose :book
      expose :chapter
      expose :author
      expose :recipient

      expose :note_url do |book, chapter, note|
        url = routes.url(
          :element,
          book_permalink: book.permalink,
          chapter_permalink: chapter.permalink,
          id: note.element_id
        )

        "#{url}#note-#{note.id}"
      end
    end
  end
end
