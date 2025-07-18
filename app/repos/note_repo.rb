# frozen_string_literal: true

module Twist
  module Repos
    class NoteRepo < Twist::DB::Repo
      def by_element(element)
        notes.by_element(element.id).to_a
      end
    end
  end
end
