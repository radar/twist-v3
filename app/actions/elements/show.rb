# frozen_string_literal: true

module Twist
  module Actions
    module Elements
      class Show < Twist::Action
        def handle(request, response)
           response.render(
            view,
            book_permalink: request.params[:book_permalink],
            chapter_permalink: request.params[:chapter_permalink],
            id: request.params[:id],
          )
        end
      end
    end
  end
end
