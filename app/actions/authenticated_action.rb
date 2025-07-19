module Twist
  module Actions
    module AuthenticatedAction
      def self.included(action_class)
        action_class.before :authenticate_user!
      end

      private

      def authenticate_user!(request, response)
        halt 401 unless request.session[:user_id]
      end
    end
  end
end
