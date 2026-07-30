require "redcarpet"

module Twist
  module Views
    module Helpers
      module NoteHelpers
        def render_markdown(text)
          Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true).render(text).html_safe
        end

        def gravatar_for(email, size: 40)
          gravatar_id = Digest::MD5::hexdigest(email.downcase)
          url = "https://www.gravatar.com/avatar/#{gravatar_id}?d=identicon&s=#{size * 2}"

          image_tag(
            url,
            alt: "",
            class: "rounded-full",
            width: size,
            height: size,
            loading: "lazy"
          )
        end
      end
    end
  end
end
