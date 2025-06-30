# frozen_string_literal: true

module Twist
  module Relations
    class Chapters < Twist::DB::Relation
      schema :chapters, infer: true do
        associations do
          belongs_to :book, relation: :books
          belongs_to :commit
        end
      end

      def by_commit(commit)
        where(commit_id: commit.id)
      end

      def by_permalink(permalink)
        where(permalink: permalink)
      end

    end
  end
end
