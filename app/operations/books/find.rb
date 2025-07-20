module Twist
  module Operations
    module Books
      class Find < Twist::Operation
        include Deps["repos.book_repo"]

        def call(permalink:)
          book_repo.find_by_permalink(permalink)
        end
      end
    end
  end
end
