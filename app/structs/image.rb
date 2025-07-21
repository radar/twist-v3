module Twist
  module Structs
    class Image < ROM::Struct
      include ImageUploader::Attachment(:image)
    end
  end
end
