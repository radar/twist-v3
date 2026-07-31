module Twist
  module Views
    module Helpers
      module RoutingHelpers
        def book_path(book)
          routes.path(:book, permalink: book.permalink)
        end

        def book_notes_path(book, status: nil)
          path = routes.path(:book_notes, book_permalink: book.permalink)

          status.nil? ? path : "#{path}?status=#{status}"
        end

        def book_people_path(book)
          routes.path(:book_people, book_permalink: book.permalink)
        end

        def book_person_path(book, person)
          routes.path(:book_person, book_permalink: book.permalink, user_id: person.id)
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

        def close_note_path(note)
          routes.path(:close_note, book_permalink:, chapter_permalink:, element_id:, id: note.id)
        end

        def open_note_path(note)
          routes.path(:open_note, book_permalink:, chapter_permalink:, element_id:, id: note.id)
        end

        def edit_note_path(note)
          routes.path(:edit_note, book_permalink:, chapter_permalink:, element_id:, id: note.id)
        end

        def update_note_path(note)
          routes.path(:update_note, book_permalink:, chapter_permalink:, element_id:, id: note.id)
        end
      end
    end
  end
end
