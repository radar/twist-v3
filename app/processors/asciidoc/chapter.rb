require_relative 'chapter_processor'

module Twist
  module Processors
    module Asciidoc
      class Chapter
        extend Dry::Initializer
        include Deps[
          "repos.chapter_repo",
          "repos.footnote_repo",
          "logger"
        ]

        param :book
        param :commit
        param :path
        param :element
        param :position, default: proc { 1 }

        def process
          title_without_number = title.gsub(/^\d+\.\s+/, '')
          position = chapter_repo.next_position(commit, part)
          chapter = chapter_repo.create(
            commit_id: commit.id,
            title: title_without_number,
            part: part,
            position: position,
            permalink: title_without_number.to_slug.normalize.to_s,
          )

          footnotes.each do |footnote|
            link_footnote(footnote, chapter)
          end

          ChapterProcessor.perform_async(book.permalink, chapter.id, element.to_s)
        end

        def part
          case title
          when /\A\d+/
            "mainmatter"
          when /\AAppendix/
            "backmatter"
          else
            "frontmatter"
          end
        end

        private

        attr_reader :book, :commit, :element, :position

        def title
          element.css("h2").first.text
        end

        def footnotes
          element.css("sup.footnote a")
        end

        def link_footnote(footnote, chapter)
          identifier = footnote["href"][1..-1]
          footnote_repo.link_to_commit_chapter(identifier, commit.id, chapter.id)
        end
      end
    end
  end
end
