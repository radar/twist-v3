# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Open < Twist::Action
        include Deps["repos.book_repo"]
        include Deps["repos.note_repo"]
        before :authenticate!

        def handle(request, response)
          book = book_repo.find_by_permalink(request.params[:book_permalink])

          unless book_repo.permitted?(book:, user: response[:current_user])
            request.flash[:error] = "You do not have permission to open notes for this book."
            response.redirect_to(routes.path(:book, permalink: book.permalink))
          end

          note_repo.open!(request.params[:id])

          request.flash[:success] = "Note re-opened successfully."

          response.redirect_to(
            routes.path(
              :element,
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
