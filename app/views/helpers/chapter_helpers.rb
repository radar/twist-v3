module Twist
  module Views
    module Helpers
      module ChapterHelpers
        include Hanami::Helpers

        def chapter_header(chapter)
          tag.ol(class: chapter.part == "frontmatter" ? "list-[lower-roman] list-inside" : "list-decimal list-inside") do
            tag.li(value: chapter.position) { chapter.title }
          end
        end
      end
    end
  end
end
