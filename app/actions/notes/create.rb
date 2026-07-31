# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Create < Twist::Action
        include Deps["repos.note_repo"]
        include Deps["repos.book_repo"]
        include Deps["repos.book_note_repo"]

        before :authenticate!

        params do
          required(:book_permalink).filled(:str?)
          required(:chapter_permalink).filled(:str?)

          required(:note).schema do
            required(:text).filled(:str?)
          end

          required(:element_id).filled(:str?)
        end

        def handle(request, response)
          book = book_repo.find_by_permalink_with_latest_commit(request.params[:book_permalink])
          note_count = book_note_repo.count_for_book(book.id)
          note_repo.create(
            request.params[:note].merge(
              number: note_count + 1,
              state: "open",
              book_id: book.id,
              element_id: request.params[:element_id],
              user_id: response[:current_user].id,
            )
          )

          response.redirect_to(
            routes.path(:element,
              book_permalink: request.params[:book_permalink],
              chapter_permalink: request.params[:chapter_permalink],
              id: request.params[:element_id]
            ),
            status: 303
          )
        end
      end
    end
  end
end
