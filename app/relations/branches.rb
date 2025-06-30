# frozen_string_literal: true

module Twist
  module Relations
    class Branches < Twist::DB::Relation
      schema :branches, infer: true do
        associations do
          has_one :latest_commit, relation: :commits, view: :latest
          belongs_to :book
        end
      end

      def default
        where(default: true)
      end
    end
  end
end
