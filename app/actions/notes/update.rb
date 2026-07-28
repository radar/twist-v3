# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Update < Twist::Action
        include Deps["repos.book_repo"]
        include Deps["repos.note_repo"]
        before :authenticate!

        params do
          required(:book_permalink).filled(:str?)
          required(:chapter_permalink).filled(:str?)
          required(:element_id).filled(:int?)
          required(:id).filled(:int?)
          required(:note).schema do
            required(:text).filled(:str?)
          end
        end

        def handle(request, response)
          book = book_repo.find_by_permalink(request.params[:book_permalink])

          unless book_repo.permitted?(book:, user: response[:current_user])
            request.flash[:error] = "You do not have permission to close notes for this book."
            response.redirect_to(routes.path(:book, permalink: book.permalink))
          end



          note_repo.update(request.params[:id], request.params[:note])
          request.flash[:success] = "Note updated successfully."
          response.redirect_to(
            routes.path(:element,
              book_permalink: request.params[:book_permalink],
              chapter_permalink: request.params[:chapter_permalink],
              id: request.params[:element_id],
            )
          )
        end
      end
    end
  end
end
