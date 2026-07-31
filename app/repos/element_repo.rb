# frozen_string_literal: true

module Twist
  module Repos
    class ElementRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      def by_chapter(chapter)
        elements.by_chapter(chapter.id)
      end

      def by_chapter_and_tag(chapter_id, tag)
        elements.where(chapter_id:).where(tag:).to_a
      end

      def chapter_id_for(id)
        elements.by_pk(id).one!.chapter_id
      end

      def find_by_chapter_and_id(chapter:, id:)
        elements
          .by_chapter(chapter.id)
          .where(elements[:id] => id)
          .one!
      end

      def delete_all_chapter_elements(chapter_id)
        elements.where(chapter_id:).delete
      end
    end
  end
end
