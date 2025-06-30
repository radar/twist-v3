# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Show < Twist::Action
        def handle(request, response)
          response.render(
            view,
            permalink: request.params[:permalink]
          )
        end
      end
    end
  end
end
