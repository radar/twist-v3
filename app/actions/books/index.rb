# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Index < Twist::Action
        before :authenticate!

        include Deps["repos.book_repo"]

        def handle(request, response)
          response.render view, user: response[:current_user]
        end
      end
    end
  end
end
