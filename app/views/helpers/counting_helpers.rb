module Twist
  module Views
    module Helpers
      module CountingHelpers
        def note_count(count)
          count == 1 ? "1 note" : "#{count} notes"
        end
      end
    end
  end
end
