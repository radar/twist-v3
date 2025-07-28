module Twist
  module Views
    module Parts
      class Element < Hanami::View::Part
        def pretty_note_count
          note_count == 1 ? "1 note" : "#{note_count} notes"
        end
      end
    end
  end
end
