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
    end
  end
end
