# frozen_string_literal: true

module Twist
  module Repos
    class ChapterRepo < Twist::DB::Repo
      PARTS = %w(frontmatter mainmatter backmatter).freeze

      commands :create, :update, use: :default_timestamps

      def by_commit(commit)
        chapters.by_commit(commit)
      end

      def mark_as_superseded(commit_id)
        by_commit(commit_id).update(superseded: true)
      end

      def for_commit_and_part(commit, part)
        current_for_commit(commit).where(part: part).to_a
      end

      def find_by_permalink_and_commit(permalink:, commit:)
        chapters
          .by_permalink(permalink)
          .by_commit(commit)
          .one!
      end

      def last_chapter_in_previous_part(commit_id, part)
        by_commit(commit_id)
          .where(superseded: false)
          .where(part: previous_part(part))
          .order { position.desc }
          .limit(1).one
      end

      def previous_chapter(commit_id, chapter)
        return last_chapter_in_previous_part(commit_id, chapter.part) if chapter.position == 1

        by_commit(commit_id)
          .where(position: chapter.position - 1, part: chapter.part)
          .limit(1).one
      end

      def next_chapter(commit_id, chapter)
        next_chapter_in_part = by_commit(commit_id)
          .where(
            part: chapter.part,
            position: chapter.position + 1,
          )
          .limit(1)
          .one

        return next_chapter_in_part if next_chapter_in_part

        by_commit(commit_id).where(part: next_part(chapter.part), position: 1).limit(1).one
      end

      def previous_part(part)
        current_index = PARTS.index(part)
        return if current_index.zero?

        PARTS[current_index - 1]
      end

      def next_part(part)
        PARTS[PARTS.index(part) + 1]
      end

      def next_position(commit, part)
        max_position = current_for_commit(commit).where(part: part).max(:position)
        max_position ? max_position + 1 : 1
      end

      private

      def current_for_commit(commit)
        by_commit(commit).where(superseded: false)
      end
    end
  end
end
