module Twist
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_repo"]
      include Deps["repos.book_repo"]

      def current_user
        return nil unless session[:user_id]

        @current_user ||= user_repo.find(session[:user_id])
      end

      def user_signed_in?
        !current_user.nil?
      end

      def nav_link_class(*paths)
        classes = ["site-nav-link"]
        classes << "site-nav-link-active" if paths.include?(current_path)
        classes.join(" ")
      end

      def current_path
        request.path
      rescue StandardError
        nil
      end

      # True when Turbo is asking for a single frame rather than a whole page. The
      # response still renders the layout, but Turbo keeps only the matching frame,
      # so anything the reader has to see (the flash) belongs inside it.
      def turbo_frame_request?
        !request.env["HTTP_TURBO_FRAME"].nil?
      rescue StandardError
        false
      end

      def author_of?(book)
        return false unless current_user

        authorships[book.id] = book_repo.author?(book: book, user: current_user) unless authorships.key?(book.id)
        authorships[book.id]
      end

      # Book authors can edit any note; everyone else only their own.
      def can_edit_note?(book:, note:)
        return false unless current_user

        note.user_id == current_user.id || author_of?(book)
      end

      # Replying is more open than editing: anyone with access to the book can
      # comment on any note on it, so authors and readers can hold a conversation.
      def can_comment_on_note?(book:)
        return false unless current_user

        permissions[book.id] = book_repo.permitted?(book: book, user: current_user) unless permissions.key?(book.id)
        permissions[book.id]
      end

      private

      def authorships
        @authorships ||= {}
      end

      def permissions
        @permissions ||= {}
      end
    end
  end
end
