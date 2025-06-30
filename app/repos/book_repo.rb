# frozen_string_literal: true

module Twist
  module Repos
    class BookRepo < Twist::DB::Repo
      commands :create, use: :timestamps, plugins_options: { timestamps: { timestamps: %i(created_at updated_at) } }

      def all
        books.to_a
      end

      def find_by_permalink(permalink)
        books.where(permalink: permalink).limit(1).one!
      end

      def find_by_permalink_with_latest_commit(permalink)
        books.combine(default_branch: :latest_commit).where(permalink: permalink).limit(1).one!
      end
    end
  end
end
