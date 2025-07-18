# frozen_string_literal: true

module Twist
  module Repos
    class ElementRepo < Twist::DB::Repo
      def by_chapter(chapter)
        elements.by_chapter(chapter.id).to_a
      end

      def find_by_chapter_and_id(chapter:, id:)
        elements
          .by_chapter(chapter.id)
          .where(elements[:id] => id)
          .one!
      end
    end
  end
end
