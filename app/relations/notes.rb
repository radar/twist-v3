# frozen_string_literal: true

module Twist
  module Relations
    class Notes < Twist::DB::Relation
      schema :notes, infer: true do
        associations do
          belongs_to :element
          belongs_to :user
          has_many :comments
        end
      end

      def by_element(element_id)
        where(element_id: element_id)
        .combine(:user)
        .combine(comments: :user)
        .order(Sequel.desc(:number))
      end

      # Open (i.e. not closed) notes for the chapters belonging to a single commit.
      def open_for_commit(commit_id)
        inner_join(:elements, id: notes[:element_id])
          .inner_join(:chapters, id: elements[:chapter_id])
          .where(chapters[:commit_id] => commit_id, chapters[:superseded] => false)
          .where { (state.is(nil)) | (state.is("open")) }
      end

      def open_counts_by_chapter(commit_id)
        notes_relation = notes
        chapters_relation = chapters

        open_for_commit(commit_id)
          .select {
            [
              chapters_relation[:id].as(:chapter_id),
              integer::count(notes_relation[:id]).as(:open_note_count)
            ]
          }
          .group(chapters_relation[:id])
          .order(chapters_relation[:id])
      end

      def open_by_commit(commit_id)
        open_for_commit(commit_id)
          .combine(:user)
          .combine(comments: :user)
          .order(Sequel.desc(notes[:number]))
      end
    end
  end
end
