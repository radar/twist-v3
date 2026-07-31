# frozen_string_literal: true

module Twist
  module Views
    module Elements
      class Show < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.chapter_repo"]
        include Deps["repos.commit_repo"]
        include Deps["repos.element_repo"]
        include Deps["repos.note_repo"]

        expose :book do |book_permalink:|
          book_repo.find_by_permalink_with_latest_commit(book_permalink)
        end

        # Notes stay attached to the element of the commit they were left against,
        # so an element link can point at any commit of the book. Resolve the
        # chapter from the element itself rather than from the latest commit.
        expose :chapter do |id:|
          chapter_repo.by_id(element_repo.chapter_id_for(id))
        end

        expose :commit do |chapter|
          commit_repo.by_id_with_branch(chapter.commit_id)
        end

        expose :element, decorate: true  do |chapter, id:|
          element_repo.find_by_chapter_and_id(chapter:, id:)
        end

        expose :notes, decorate: true do |element|
          note_repo.by_element(element)
        end
      end
    end
  end
end
