require "redcarpet"

module Twist
  module Views
    module Helpers
      module NoteHelpers
        def render_markdown(text)
          Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true).render(text).html_safe
        end

        def gravatar_for(email)
          gravatar_id = Digest::MD5::hexdigest(email.downcase)
          url = "https://www.gravatar.com/avatar/#{gravatar_id}?d=identicon"

          image_tag(url, alt: "User Avatar", class: "rounded-full w-24")


        end
      end
    end
  end
end
