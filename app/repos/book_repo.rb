# frozen_string_literal: true

require 'default_timestamps'

module Twist
  module Repos
    class BookRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

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
