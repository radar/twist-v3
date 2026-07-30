module Twist
  module Operations
    module Books
      class Find < Twist::Operation
        include Deps["repos.book_repo"]

        def call(permalink:)
          book = book_repo.by_permalink(permalink)

          step Failure(:book_not_found) if book.nil?

          book
        end
      end
    end
  end
end
