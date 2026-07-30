module Twist
  module Views
    module Helpers
      module ChapterHelpers
        ROMAN_NUMERALS = %w[i ii iii iv v vi vii viii ix x xi xii].freeze

        # Frontmatter is numbered in lower-roman, everything else in decimal.
        def chapter_number(chapter)
          return chapter.position.to_s unless chapter.part == "frontmatter"

          ROMAN_NUMERALS[chapter.position - 1] || chapter.position.to_s
        end
      end
    end
  end
end
