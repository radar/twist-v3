# frozen_string_literal: true

module Twist
  module Repos
    class ElementRepo < Twist::DB::Repo
      def by_chapter(chapter)
        elements.by_chapter(chapter.id).to_a
      end
    end
  end
end
