module Twist
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_repo"]

      def current_user
        return nil unless session[:user_id]

        @current_user ||= user_repo.find(session[:user_id])
      end

      def user_signed_in?
        !current_user.nil?
      end
    end
  end
end
