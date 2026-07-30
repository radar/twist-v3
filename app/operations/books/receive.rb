module Twist
  module Operations
    module Books
      class Receive < Twist::Operation
        include Deps[find_or_create_branch: "operations.branches.find_or_create"]
        include Deps[find_book: "operations.books.find"]

        def call(permalink:, branch_name: "master")
          book = step find_book.(permalink: permalink)
          branch = step find_or_create_branch.(book_id: book.id, ref: branch_name)

          worker = case book.format
                   when "markdown"
                      Twist::Processors::Markdown::BookWorker
                    when "asciidoc"
                      Twist::Processors::Asciidoc::BookWorker
                    else
                      raise "unknown format"
                    end

          worker.perform_async(
            "permalink" => book.permalink,
            "branch" => branch.name,
            "username" => book.github_user,
            "repo" => book.github_repo,
          )
        end
      end
    end
  end
end
