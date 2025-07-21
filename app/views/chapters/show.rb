# frozen_string_literal: true

module Twist
  module Views
    module Chapters
      class Show < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.chapter_repo"]
        include Deps["repos.commit_repo"]
        include Deps["repos.element_repo"]
        include Deps["repos.footnote_repo"]

        expose :book do |book_permalink:|
          book_repo.find_by_permalink_with_latest_commit(book_permalink)
        end

        expose :commit do |book_permalink:|
          commit_repo.latest_by_book_permalink(book_permalink:)
        end

        expose :chapter do |commit, permalink:|
          chapter_repo.find_by_permalink_and_commit(permalink:, commit: commit)
        end

        expose :elements do |chapter|
          element_repo.by_chapter(chapter)
        end

        expose :previous_chapter do |commit, chapter|
          chapter_repo.previous_chapter(commit, chapter)
        end

        expose :next_chapter do |commit, chapter|
          chapter_repo.next_chapter(commit, chapter)
        end

        expose :footnotes do |chapter, commit|
          footnote_repo.by_chapter_and_commit(chapter.id, commit.id)
        end
      end
    end
  end
end
