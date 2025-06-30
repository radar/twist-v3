# frozen_string_literal: true

module Twist
  class Routes < Hanami::Routes
    root to: "books.index"
    get "/books", to: "books.index"
    get "/books/:permalink", to: "books.show", as: :book

    get "/books/:book_permalink/chapters/:permalink", to: "chapters.show", as: :chapter
    get "/chapters/:id", to: "chapters.show"
  end
end
