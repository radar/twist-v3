# frozen_string_literal: true

module Twist
  module Views
    module Books
      class Index < Twist::View
        include Deps["repos.book_repo"]
        expose :user, private: true

        expose :books do |user|
          book_repo.permitted_for_user(user)
        end
      end
    end
  end
end
