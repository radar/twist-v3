# frozen_string_literal: true

module Twist
  module Actions
    module Comments
      class Create < Twist::Action
        include Deps["repos.book_repo"]
        include Deps["repos.note_repo"]
        include Deps["repos.comment_repo"]
        include Twist::Actions::Notes::NoteAuthorization

        before :authenticate!

        params do
          required(:book_permalink).filled(:str?)
          required(:chapter_permalink).filled(:str?)
          required(:element_id).filled(:str?)
          # `:integer` rather than the `:int?` predicate: only a type name makes
          # dry-schema coerce the id out of the URL string before checking it.
          required(:id).filled(:integer)

          required(:comment).schema do
            required(:text).filled(:str?)
          end
        end

        def handle(request, response)
          book = book_repo.by_permalink(request.params[:book_permalink])

          unless book
            request.flash[:error] = "That book could not be found."
            response.redirect_to(routes.path(:books))
            return
          end

          book_path = routes.path(:book, permalink: book.permalink)

          unless can_comment_on_note?(book:, user: response[:current_user])
            request.flash[:error] = "Only people with access to this book can comment on its notes."
            response.redirect_to(book_path)
            return
          end

          # `filled` still accepts a textarea holding nothing but whitespace, so
          # strip before deciding whether there is anything to save. An empty
          # comment is a slip of the finger rather than an error worth a 500, so
          # send the reader back to the note they were replying to.
          text = request.params.valid? ? request.params[:comment][:text].strip : ""

          if text.empty?
            request.flash[:error] = "Your comment needs some text before it can be saved."
            response.redirect_to(element_path(request), status: 303)
            return
          end

          # The note id comes from the URL, so check it really is a note on this
          # book before commenting on it.
          note = note_repo.find_by_book_and_id(book, request.params[:id])

          unless note
            request.flash[:error] = "That note could not be found on this book."
            response.redirect_to(book_path)
            return
          end

          comment_repo.create(
            note_id: note.id,
            user_id: response[:current_user].id,
            text: text
          )

          request.flash[:success] = "Comment added successfully."

          response.redirect_to(element_path(request), status: 303)
        end

        private

        def element_path(request)
          routes.path(
            :element,
            book_permalink: request.params[:book_permalink],
            chapter_permalink: request.params[:chapter_permalink],
            id: request.params[:element_id]
          )
        end
      end
    end
  end
end
