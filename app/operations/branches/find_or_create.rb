module Twist
  module Operations
    module Branches
      class FindOrCreate < Twist::Operation
        include Deps["repos.branch_repo"]

        def call(book_id:, ref:)
          branch = ref.split("/").last
          branch_repo.find_or_create_by_book_id_and_name(book_id, branch)
        end
      end
    end
  end
end
