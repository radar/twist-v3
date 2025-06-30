# frozen_string_literal: true

module Twist
  module Repos
    class CommitRepo < Twist::DB::Repo
      commands :create, use: :timestamps, plugins_options: { timestamps: { timestamps: %i(created_at updated_at) } }

      def latest_by_book_permalink(book_permalink:)
        commits.latest_by_book_permalink(book_permalink:)
      end
    end
  end
end
