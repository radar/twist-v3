# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Index < Twist::Action
        before :authenticate!
        before :ensure_authenticated!

        include Deps["repos.book_repo"]

        require 'pry'

        def handle(request, response)
          binding.pry
          response.render view, user: response[:current_user]
        end
      end
    end
  end
end
