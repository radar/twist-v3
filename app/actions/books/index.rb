# frozen_string_literal: true

module Twist
  module Actions
    module Books
      class Index < Twist::Action
        include Deps["repos.book_repo"]
        def handle(request, response)


        end
      end
    end
  end
end
