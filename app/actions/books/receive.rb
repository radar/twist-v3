# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Receive < Twist::Action
        include Deps[receive_book: "operations.books.receive"]

        def verify_csrf_token?(request, response)
          false
        end

        def handle(request, response)
          payload = JSON.parse(request.params[:payload])

          result = receive_book.(
            permalink: request.params[:permalink],
            branch_name: payload["ref"],
            event: request.env["HTTP_X_GITHUB_EVENT"],
            delivery_id: request.env["HTTP_X_GITHUB_DELIVERY"]
          )

          case result
          in Failure(:book_not_found)
            response.status = 404
            response.format = :json
            response.body = {error: "Book not found"}.to_json
          else
            response.status = 200
          end
        end
      end
    end
  end
end
