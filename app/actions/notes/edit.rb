# frozen_string_literal: true

module Twist
  module Actions
    module Notes
      class Edit < Twist::Action
        include Deps["repos.book_repo"]
        include Deps["repos.note_repo"]
        include NoteAuthorization
        before :authenticate!

        def handle(request, response)
          book = book_repo.find_by_permalink(request.params[:book_permalink])
          note = note_repo.find_by_book_and_id(book, request.params[:id])

          unless can_edit_note?(book:, note:, user: response[:current_user])
            request.flash[:error] = "You can only edit your own notes."
            response.redirect_to(routes.path(:book, permalink: book.permalink))
          end
        end
      end
    end
  end
end
