# frozen_string_literal: true

module Twist
  module Repos
    class BranchRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def find_by_book_id_and_name(book_id, name)
        branches.where(
          book_id: book_id,
          name: name,
        ).limit(1).one
      end
    end
  end
end
