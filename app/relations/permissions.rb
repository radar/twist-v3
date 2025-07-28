# frozen_string_literal: true

module Twist
  module Relations
    class Permissions < Twist::DB::Relation
      schema :permissions, infer: true
    end
  end
end
