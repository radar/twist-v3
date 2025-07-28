module Twist
  module Views
    module Parts
      class Note < Hanami::View::Part
        def text_markdown
          Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true).render(text).html_safe
        end

      end
    end
  end
end
