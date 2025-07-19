# frozen_string_literal: true

module Twist
  module Relations
    class BookNotes < Twist::DB::Relation
      schema :book_notes, infer: true
    end
  end
end
