# frozen_string_literal: true

module Twist
  module Actions
    module Webhooks
      # Generates a new webhook secret for a book. Doing this for the first time
      # is what turns signature verification on, so the author has to paste the
      # new secret into GitHub before the next push will be accepted.
      class RotateSecret < Twist::Action
        include Deps["repos.book_repo"]
        include Twist::Actions::BookAuthorOnly

        before :authenticate!
        before :ensure_authenticated!

        def handle(request, response)
          book = authored_book(request, response)
          return unless book

          replacing = !book.webhook_secret.nil?
          book_repo.rotate_webhook_secret(book)

          request.flash[:success] =
            if replacing
              "New webhook secret generated. Update it in GitHub, or pushes will " \
                "stop being accepted."
            else
              "Webhook secret generated. Twist now only accepts pushes signed " \
                "with it, so add it to the webhook in GitHub."
            end

          response.redirect_to routes.path(:book_webhooks, book_permalink: book.permalink)
        end

        private

        def author_only_message
          "Only this book's authors can change its webhook secret."
        end
      end
    end
  end
end
