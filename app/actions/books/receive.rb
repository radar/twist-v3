# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Receive < Twist::Action
        include Deps[receive_book: "operations.books.receive"]
        include Deps[find_book: "operations.books.find"]

        GITHUB_EVENT_HEADER = "HTTP_X_GITHUB_EVENT"

        def verify_csrf_token?(request, response)
          false
        end

        def handle(request, response)
          if request.get_header(GITHUB_EVENT_HEADER) == "ping"
            handle_ping(request, response)
          else
            handle_push(request, response)
          end
        end

        private

        # GitHub sends a ping when a webhook is first created. There's nothing
        # to process, but we still check the book exists so a webhook pointed at
        # the wrong permalink fails loudly in GitHub's UI.
        def handle_ping(request, response)
          case find_book.(permalink: request.params[:permalink])
          in Failure(:book_not_found)
            book_not_found(response)
          else
            response.status = 200
            response.format = :json
            response.body = {message: "pong"}.to_json
          end
        end

        def handle_push(request, response)
          payload = JSON.parse(request.params[:payload])

          result = receive_book.(
            permalink: request.params[:permalink],
            branch_name: payload["ref"]
          )

          case result
          in Failure(:book_not_found)
            book_not_found(response)
          else
            response.status = 200
          end
        end

        def book_not_found(response)
          response.status = 404
          response.format = :json
          response.body = {error: "Book not found"}.to_json
        end
      end
    end
  end
end
