module Twist
  module Views
    module Helpers
      module RoutingHelpers
        def book_path(book)
          routes.path(:book, permalink: book.permalink)
        end

        def chapter_path(book, chapter)
          routes.path(:chapter, book_permalink: book.permalink, permalink: chapter.permalink)
        end

        def element_path(book:, chapter:, id:)
          routes.path(
            :element,
            book_permalink: book.permalink,
            chapter_permalink: chapter.permalink,
            id: id
          )
        end

        def create_note_path(element_id:)
          routes.path(
            :create_note,
            book_permalink: book.permalink,
            chapter_permalink: chapter.permalink,
            element_id: element_id
          )
        end
      end
    end
  end
end
