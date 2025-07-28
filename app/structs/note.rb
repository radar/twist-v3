module Twist
  module Structs
    class Note < ROM::Struct
      def open?
        state == 'open'
      end

      def closed?
        state == 'closed'
      end
    end
  end
end
