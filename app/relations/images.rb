# frozen_string_literal: true

module Twist
  module Relations
    class Images < Twist::DB::Relation
      schema :images, infer: true
    end
  end
end
