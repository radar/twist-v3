module Twist
  module Operations
    module Books
      class Receive < Twist::Operation
        include Deps[find_or_create_branch: "operations.branches.find_or_create"]
        include Deps[find_book: "operations.books.find"]
        include Deps["repos.webhook_repo"]

        def call(permalink:, branch_name: "master", event: nil, delivery_id: nil)
          book = step find_book.(permalink: permalink)

          webhook = webhook_repo.record_received(
            book: book,
            event: event,
            ref: branch_name,
            delivery_id: delivery_id
          )

          branch = step find_or_create_branch.(book_id: book.id, ref: branch_name)

          worker = case book.format
                   when "markdown"
                      Twist::Processors::Markdown::BookWorker
                    when "asciidoc"
                      Twist::Processors::Asciidoc::BookWorker
                    else
                      raise "unknown format"
                    end

          job_id = worker.perform_async(
            "permalink" => book.permalink,
            "branch" => branch.name,
            "username" => book.github_user,
            "repo" => book.github_repo,
            "webhook_id" => webhook.id,
          )

          webhook_repo.mark_enqueued(webhook.id, job_id: job_id)

          job_id
        end
      end
    end
  end
end
