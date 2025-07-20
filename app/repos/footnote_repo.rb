# frozen_string_literal: true

module Twist
  module Repos
    class FootnoteRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def by_identifier(identifier)
        footnotes.where(identifier: identifier).first
      end

      def by_identifier_and_chapter(identifier, chapter)
        footnotes
          .where(identifier: identifier, chapter_id: chapter.id)
          .first
      end

      def find_or_create(fields)
        footnote = footnotes.where(
          commit_id: fields[:commit_id],
          identifier: fields[:identifier],
        ).first

        return footnote if footnote

        create(fields)
      end

      def for_commit(commit)
        footnotes.where(commit_id: commit.id).to_a
      end

      def link_to_commit_chapter(identifier, commit_id, chapter_id)
        footnotes
          .where(identifier: identifier, commit_id: commit_id)
          .update(chapter_id: chapter_id)
      end
    end
  end
end
