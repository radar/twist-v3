# frozen_string_literal: true

module Twist
  module Relations
    class Elements < Twist::DB::Relation
      schema :elements, infer: true do
        associations do
          belongs_to :image
        end
      end

      def by_chapter(chapter_id)
        notes_relation = notes
        select_append { integer::count(notes_relation[:id]).as(:note_count) }
          .where(elements[:chapter_id] => chapter_id)
          .left_join(:notes, element_id: :id)
          .left_join(:images, id: elements[:image_id])
          .group(:id)
          .combine(:images)
          .order { id.asc }
      end
    end
  end
end
