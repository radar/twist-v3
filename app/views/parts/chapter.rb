module Twist
  module Views
    module Parts
      class Chapter < Hanami::View::Part
        def link
          list_class = part == "frontmatter" ? "list-[lower-roman]" : "list-decimal"
          helpers.tag.ol(class: list_class + " list-inside inline-block") do
            helpers.tag.li(value: position) { title }
          end
        end
        def header
          list_class = part == "frontmatter" ? "list-[lower-roman]" : "list-decimal"
          helpers.tag.ol(class: list_class + " list-inside inline-block") do
            helpers.tag.li(value: position) { title }
          end
        end
      end
    end
  end
end
