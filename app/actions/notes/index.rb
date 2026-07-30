# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Index < Twist::Action
        def handle(request, response)
          response.render(
            view,
            book_permalink: request.params[:book_permalink]
          )
        end
      end
    end
  end
end
