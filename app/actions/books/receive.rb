# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Receive < Twist::Action
        include Deps[find_book: "operations.books.find"]
        include Deps[find_or_create_branch: "operations.branches.find_or_create"]

        def handle(request, response)
          payload = JSON.parse(request.params[:payload])
          book = find_book.(permalink: request.params[:permalink])
          unless book
            halt 404, JSON.generate(error: "Book not found")
            return
          end

           branch = find_or_create_branch.(book_id: book.id, ref: payload["ref"])
           worker = case book.format
                    when "markdown"
                      Twist::Processors::Markdown::BookWorker
                    when "asciidoc"
                      Twist::Processors::Asciidoc::BookWorker
                    else
                      raise "unknown format"
                    end
            username, repo = payload["repository"]["full_name"].split("/")

            worker.perform_async(
              permalink: book.permalink,
              branch: branch.name,
              username: username,
              repo: repo,
            )

          200
        end
      end
    end
  end
end
