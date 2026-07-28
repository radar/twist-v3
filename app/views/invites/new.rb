# frozen_string_literal: true

module Twist
  module Views
    module Invites
      class New < Twist::View
        include Deps["repos.book_repo"]

        expose :user, private: true

        expose :books do |user|
          book_repo.authored_by(user)
        end
      end
    end
  end
end
