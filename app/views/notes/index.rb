# frozen_string_literal: true

module Twist
  module Views
    module Notes
      class Index < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.note_repo"]

        expose :status

        expose :book do |book_permalink:|
          book_repo.find_by_permalink_with_latest_commit(book_permalink)
        end

        expose :commit do |book|
          book.default_branch.latest_commit
        end

        expose :notes, decorate: true do |commit, status|
          if status == "closed"
            note_repo.closed_by_commit(commit)
          else
            note_repo.open_by_commit(commit)
          end
        end

        expose :open_count do |commit|
          note_repo.open_count_by_commit(commit)
        end

        expose :closed_count do |commit|
          note_repo.closed_count_by_commit(commit)
        end
      end
    end
  end
end
