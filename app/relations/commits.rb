# frozen_string_literal: true

module Twist
  module Relations
    class Commits < Twist::DB::Relation
      schema :commits, infer: true do
        associations do
          belongs_to :branch
        end
      end

      def latest
        order { created_at.desc }.limit(1)
      end

      def latest_by_book_permalink(book_permalink:)
        latest.combine(:branch).inner_join(:branches, id: commits[:branch_id]).inner_join(:books, permalink: book_permalink).one!
      end
    end
  end
end
