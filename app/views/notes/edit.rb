# frozen_string_literal: true

module Twist
  module Views
    module Notes
      class Edit < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.chapter_repo"]
        include Deps["repos.commit_repo"]
        include Deps["repos.element_repo"]
        include Deps["repos.note_repo"]

        expose :book do |book_permalink:|
          book_repo.find_by_permalink_with_latest_commit(book_permalink)
        end

        # As on the element page: the note's element may belong to an older commit,
        # so take the chapter from the element instead of the latest commit.
        expose :chapter do |element_id:|
          chapter_repo.by_id(element_repo.chapter_id_for(element_id))
        end

        expose :commit do |chapter|
          commit_repo.by_id_with_branch(chapter.commit_id)
        end

        expose :element, decorate: true do |chapter, element_id:|
          element_repo.find_by_chapter_and_id(chapter:, id: element_id)
        end

        expose :note do |book, id:|
          note_repo.find_by_book_and_id(book, id)
        end

        expose :book_permalink do |book|
          book.permalink
        end

        expose :chapter_permalink do |chapter|
          chapter.permalink
        end

        expose :element_id do |element|
          element.id
        end
      end
    end
  end
end
