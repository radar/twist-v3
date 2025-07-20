module Twist
  module Structs
    class Book < ROM::Struct
      attribute :id, Types::Integer
      attribute :permalink, Types::String
      attribute :format, Types::String
    end
  end
end
