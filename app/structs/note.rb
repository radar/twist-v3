module Twist
  module Structs
    class Note < ROM::Struct
      # Notes predating the `state` column have no state, and count as open.
      def open?
        !closed?
      end

      def closed?
        state == 'closed'
      end
    end
  end
end
