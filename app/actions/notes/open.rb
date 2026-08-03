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

          unless book_repo.author?(book:, user: response[:current_user])
            request.flash[:error] = "Only this book's authors can re-open notes."
            response.redirect_to(routes.path(:book, permalink: book.permalink))
          end

          note_repo.open!(request.params[:id])

          request.flash[:success] = "Note re-opened successfully."

          element_path = routes.path(
            :element,
            book_permalink: request.params[:book_permalink],
            chapter_permalink: request.params[:chapter_permalink],
            id: request.params[:element_id]
          )

          response.redirect_to(return_path(request, fallback: element_path), status: 303)
        end
      end
    end
  end
end
