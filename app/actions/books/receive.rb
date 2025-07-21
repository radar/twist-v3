# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Receive < Twist::Action
        include Deps[find_book: "operations.books.find"]
        include Deps[find_or_create_branch: "operations.branches.find_or_create"]

        def verify_csrf_token?(request, response)
          false
        end

        def handle(request, response)
          payload = JSON.parse(request.params[:payload])
          book_result = find_book.(permalink: request.params[:permalink])
          if book_result.failure?
            halt 404, JSON.generate(error: "Book not found")
            return
          end

          book = book_result.value!
          branch = find_or_create_branch.(book_id: book.id, ref: payload["ref"])
          if branch.failure?
            halt 500, JSON.generate(error: "Failed to create or find branch")
            return
          end

          branch = branch.value!
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
            "permalink" => book.permalink,
            "branch" => branch.name,
            "username" => username,
            "repo" => repo,
          )

          200
        end
      end
    end
  end
end
