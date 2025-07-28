# frozen_string_literal: true

module Twist
  module Views
    module Books
      class Show < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.chapter_repo"]

        expose :book do |permalink:|
          book_repo.find_by_permalink_with_latest_commit(permalink)
        end

        expose :chapters do |book|
          chapter_repo.by_commit(book.default_branch.latest_commit).to_a.group_by(&:part)
        end
      end
    end
  end
end
