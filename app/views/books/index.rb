# frozen_string_literal: true

module Twist
  module Views
    module Books
      class Index < Twist::View
        include Deps["repos.book_repo"]
        expose :books do
          book_repo.all
        end
      end
    end
  end
end
