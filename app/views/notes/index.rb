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

        expose :notes, decorate: true do |book, status|
          if status == "closed"
            note_repo.closed_by_book(book)
          else
            note_repo.open_by_book(book)
          end
        end

        expose :open_count do |book|
          note_repo.open_count_by_book(book)
        end

        expose :closed_count do |book|
          note_repo.closed_count_by_book(book)
        end
      end
    end
  end
end
