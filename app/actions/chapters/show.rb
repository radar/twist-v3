# frozen_string_literal: true

module Twist
  module Actions
    module Chapters
      class Show < Twist::Action
        def handle(request, response)
           response.render(
            view,
            book_permalink: request.params[:book_permalink],
            permalink: request.params[:permalink]
          )
        end
      end
    end
  end
end
