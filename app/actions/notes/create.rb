# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Create < Twist::Action
        include Deps["repos.note_repo"]

        params do
          required(:book_permalink).filled(:str?)
          required(:chapter_permalink).filled(:str?)

          required(:note).schema do
            required(:text).filled(:str?)
          end

          required(:element_id).filled(:str?)
        end

        def handle(request, response)
          note_repo.create(
            request.params[:note].merge(
              element_id: request.params[:element_id],
              user_id: 1,
            )
          )

          response.redirect_to(
            routes.path(:element,
              book_permalink: request.params[:book_permalink],
              chapter_permalink: request.params[:chapter_permalink],
              id: request.params[:element_id]
            )
          )
        end
      end
    end
  end
end
