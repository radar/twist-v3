# frozen_string_literal: true

module Twist
  module Relations
    class Books < Twist::DB::Relation
      schema :books, infer: true do
        associations do
          has_many :branches
          has_one :default_branch, relation: :branches, view: :default
        end
      end
    end
  end
end
