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

          receive_book.(permalink: request.params[:permalink], branch_name: payload["ref"])

          200
        end
      end
    end
  end
end
