# frozen_string_literal: true

module Twist
  module Relations
    class InviteBooks < Twist::DB::Relation
      schema :invite_books, infer: true
    end
  end
end
