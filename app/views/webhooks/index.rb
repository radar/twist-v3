# frozen_string_literal: true

module Twist
  module Views
    module Webhooks
      class Index < Twist::View
        include Deps["repos.webhook_repo"]
        include Deps["routes"]

        expose :book

        # The absolute URL GitHub should be pointed at.
        expose :receive_url do |book|
          routes.url(:book_receive, permalink: book.permalink).to_s
        end

        expose :webhooks do |book|
          webhook_repo.recent_for_book(book)
        end
      end
    end
  end
end
