# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Index < Twist::Action
        STATUSES = %w[open closed].freeze

        def handle(request, response)
          response.render(
            view,
            book_permalink: request.params[:book_permalink],
            status: status_for(request)
          )
        end

        private

        # Anything other than an explicit "closed" shows the open notes.
        def status_for(request)
          status = request.params[:status]

          STATUSES.include?(status) ? status : "open"
        end
      end
    end
  end
end
