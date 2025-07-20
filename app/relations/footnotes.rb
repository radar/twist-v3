# frozen_string_literal: true

module Twist
  module Relations
    class Footnotes < Twist::DB::Relation
      schema :footnotes, infer: true
    end
  end
end
