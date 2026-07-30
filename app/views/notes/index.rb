# frozen_string_literal: true

module Twist
  module Views
    module Notes
      class Index < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.note_repo"]

        expose :book do |book_permalink:|
          book_repo.find_by_permalink_with_latest_commit(book_permalink)
        end

        expose :commit do |book|
          book.default_branch.latest_commit
        end

        expose :notes, decorate: true do |commit|
          note_repo.open_by_commit(commit)
        end
      end
    end
  end
end
