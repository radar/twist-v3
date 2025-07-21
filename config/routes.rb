# frozen_string_literal: true

module Twist
  class Routes < Hanami::Routes
    root to: "books.index"
    get "/books", to: "books.index"
    get "/books/:permalink", to: "books.show", as: :book
    post "/books/:permalink/receive", to: "books.receive"

    get "/books/:book_permalink/chapters/:permalink", to: "chapters.show", as: :chapter
    get "/books/:book_permalink/chapters/:chapter_permalink/elements/:id", to: "elements.show", as: :element

    post "/books/:book_permalink/chapters/:chapter_permalink/elements/:element_id/notes", to: "notes.create", as: :create_note
    post "/notes", to: "notes.create"

    post "/login", to: "sessions.create", as: :login_post
    get "/login/new", to: "sessions.new", as: :login
    post "/sessions", to: "sessions.create"

  end
end
