# frozen_string_literal: true

module Twist
  module Relations
    class Notes < Twist::DB::Relation
      schema :notes, infer: true
    end
  end
end
