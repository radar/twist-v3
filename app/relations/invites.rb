# frozen_string_literal: true

module Twist
  module Relations
    class Invites < Twist::DB::Relation
      schema :invites, infer: true
    end
  end
end
