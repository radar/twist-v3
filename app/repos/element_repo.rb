# frozen_string_literal: true

module Twist
  module Repos
    class ElementRepo < Twist::DB::Repo
      def by_chapter(chapter)
        elements
          .where(chapter_id: chapter)
          .order { id.asc }
      end
    end
  end
end
