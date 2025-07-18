# frozen_string_literal: true

module Twist
  module Relations
    class Users < Twist::DB::Relation
      schema :users, infer: true
    end
  end
end
