# frozen_string_literal: true

module Twist
  module Views
    module Books
      class Show < Twist::View
        include Deps["repos.book_repo"]
        include Deps["repos.chapter_repo"]
        include Deps["repos.note_repo"]

        SECTIONS = [
          ["frontmatter", "Frontmatter"],
          ["mainmatter", "Chapters"],
          ["backmatter", "Appendices"]
        ].freeze

        expose :book do |permalink:|
          book_repo.find_by_permalink_with_latest_commit(permalink)
        end

        expose :commit, private: true do |book|
          book.default_branch.latest_commit
        end

        # [label, chapters] per part, in reading order, skipping empty parts.
        expose :chapter_sections do |commit|
          chapters = chapter_repo.by_commit(commit).to_a.group_by(&:part)

          SECTIONS.filter_map do |part, label|
            next if chapters[part].nil? || chapters[part].empty?

            [label, chapters[part]]
          end
        end

        # Per-chapter badges only make sense for the current commit's chapters.
        expose :open_note_counts do |commit|
          note_repo.open_counts_by_chapter(commit)
        end

        # The pill links to every open note on the book, including ones left
        # against earlier commits, so it can't be summed from the per-chapter counts.
        expose :open_note_count do |book|
          note_repo.open_count_by_book(book)
        end
      end
    end
  end
end
