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

        expose :commit do |book_permalink:|
          commit_repo.latest_by_book_permalink(book_permalink:)
        end

        expose :chapter do |commit, chapter_permalink:|
          chapter_repo.find_by_permalink_and_commit(permalink: chapter_permalink, commit: commit)
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
