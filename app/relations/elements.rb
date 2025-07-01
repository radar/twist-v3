# frozen_string_literal: true

module Twist
  module Relations
    class Elements < Twist::DB::Relation
      schema :elements, infer: true

      def by_chapter(chapter_id)
        notes_relation = notes
        select_append { integer::count(notes_relation[:id]).as(:note_count) }
          .where(chapter_id: chapter_id)
          .left_join(:notes, element_id: :id)
          .group(:id)
          .order { id.asc }
      end
    end
  end
end
