# frozen_string_literal: true

module Twist
  module Mailers
    # Tells everyone in a note's conversation that someone has replied. One
    # email per recipient, sent from CommentNotificationWorker.
    class CommentNotification < Hanami::Mailer
      include Deps["settings", "routes"]

      from { settings.mail_from }
      to { |recipient| recipient.email }
      subject { |book, note| "New reply to note ##{note.number} on #{book.title}" }

      expose :comment
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
