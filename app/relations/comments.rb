# frozen_string_literal: true

module Twist
  module Relations
    class Comments < Twist::DB::Relation
      schema :comments, infer: true do
        associations do
          belongs_to :note
          belongs_to :user
        end
      end
    end
  end
end
