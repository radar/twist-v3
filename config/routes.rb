# frozen_string_literal: true

module Twist
  class Routes < Hanami::Routes
    root to: "books.index"
    get "/books", to: "books.index"
    get "/books/:permalink", to: "books.show", as: :book
    post "/books/:permalink/receive", to: "books.receive"

    get "/books/:book_permalink/chapters/:permalink", to: "chapters.show", as: :chapter
    get "/books/:book_permalink/chapters/:chapter_permalink/elements/:id", to: "elements.show", as: :element

    note_prefix = "/books/:book_permalink/chapters/:chapter_permalink/elements/:element_id/notes"
    post note_prefix, to: "notes.create", as: :create_note
    patch "#{note_prefix}/:id/close", to: "notes.close", as: :close_note
    patch "#{note_prefix}/:id/open", to: "notes.open", as: :open_note
    patch "#{note_prefix}/:id", to: "notes.update", as: :update_note
    get "#{note_prefix}/:id/edit", to: "notes.edit", as: :edit_note

    get "/invites/new", to: "invites.new", as: :new_invite
    post "/invites", to: "invites.create", as: :create_invite
    get "/invites/:token", to: "invites.show", as: :invite
    post "/invites/:token/accept", to: "invites.accept", as: :accept_invite

    post "/login", to: "sessions.create", as: :login_post
    get "/login/new", to: "sessions.new", as: :login
    post "/sessions", to: "sessions.create"
    get "/notes/:id/edit", to: "notes.edit"
    patch "/notes/:id", to: "notes.update"
  end
end
