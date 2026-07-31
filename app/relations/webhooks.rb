# frozen_string_literal: true

module Twist
  module Relations
    class Webhooks < Twist::DB::Relation
      schema :webhooks, infer: true
    end
  end
end
