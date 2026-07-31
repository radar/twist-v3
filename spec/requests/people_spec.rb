# frozen_string_literal: true

RSpec.describe "People", :db, type: :request do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:invite_repo) { Hanami.app["repos.invite_repo"] }

  let(:author) do
    user_repo.create(name: "Author", email: "author@example.com", password: "password123")
  end

  let(:reader) do
    user_repo.create(name: "Reader", email: "reader@example.com", password: "password123")
  end

  let(:book) do
    book_repo.create(title: "Exploding Rails", permalink: "exploding-rails", format: "markdown")
  end

  let(:other_book) do
    book_repo.create(title: "Other Book", permalink: "other-book", format: "markdown")
  end

  before do
    book_repo.grant_permission(book: book, user: author, author: true)
    book_repo.grant_permission(book: book, user: reader, author: false)
  end

  def sign_in(user)
    post "/sessions", session: {email: user.email, password: "password123"}
  end

  describe "GET /books/:book_permalink/people" do
    it "redirects when not signed in" do
      get "/books/#{book.permalink}/people"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/login/new")
    end

    it "redirects a non-author back to the book" do
      sign_in(reader)
      get "/books/#{book.permalink}/people"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
    end

    it "lists people with their role" do
      sign_in(author)
      get "/books/#{book.permalink}/people"

      expect(last_response).to be_successful
      expect(last_response.body).to include("author@example.com")
      expect(last_response.body).to include("reader@example.com")
      expect(last_response.body).to include("people-role-author")
      expect(last_response.body).to include("people-role-reader")
      expect(last_response.body).to include("Make author")
    end

    it "offers no remove button for the last author" do
      sign_in(author)
      get "/books/#{book.permalink}/people"

      expect(last_response.body).not_to include("Remove author")
    end

    it "offers a remove button once a second author exists" do
      book_repo.set_author(book: book, user: reader, author: true)

      sign_in(author)
      get "/books/#{book.permalink}/people"

      expect(last_response.body).to include("Remove author")
    end

    it "lists pending invites for this book only" do
      invite_repo.create_for(email: "pending@example.com", invited_by: author, book_ids: [book.id])
      invite_repo.create_for(email: "elsewhere@example.com", invited_by: author, book_ids: [other_book.id])

      accepted = invite_repo.create_for(
        email: "accepted@example.com",
        invited_by: author,
        book_ids: [book.id]
      )
      invite_repo.accept!(accepted)

      sign_in(author)
      get "/books/#{book.permalink}/people"

      expect(last_response.body).to include("pending@example.com")
      expect(last_response.body).not_to include("elsewhere@example.com")
      expect(last_response.body).not_to include("accepted@example.com")
      expect(last_response.body).to include("Invited by Author")
    end
  end

  describe "PATCH /books/:book_permalink/people/:user_id" do
    it "promotes a reader to author" do
      sign_in(author)
      patch "/books/#{book.permalink}/people/#{reader.id}", person: {author: "true"}

      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}/people")
      expect(book_repo.author?(book: book, user: reader)).to be(true)
    end

    it "demotes an author back to reader" do
      book_repo.set_author(book: book, user: reader, author: true)

      sign_in(author)
      patch "/books/#{book.permalink}/people/#{reader.id}", person: {author: "false"}

      expect(book_repo.author?(book: book, user: reader)).to be(false)
      expect(book_repo.permitted?(book: book, user: reader)).to be(true)
    end

    it "refuses to demote the last author" do
      sign_in(author)
      patch "/books/#{book.permalink}/people/#{author.id}", person: {author: "false"}

      expect(book_repo.author?(book: book, user: author)).to be(true)
    end

    it "refuses changes from a non-author" do
      sign_in(reader)
      patch "/books/#{book.permalink}/people/#{author.id}", person: {author: "false"}

      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
      expect(book_repo.author?(book: book, user: author)).to be(true)
    end

    it "refuses to change someone without access to the book" do
      stranger = user_repo.create(
        name: "Stranger",
        email: "stranger@example.com",
        password: "password123"
      )

      sign_in(author)
      patch "/books/#{book.permalink}/people/#{stranger.id}", person: {author: "true"}

      expect(book_repo.permitted?(book: book, user: stranger)).to be(false)
    end

    it "redirects when not signed in" do
      patch "/books/#{book.permalink}/people/#{reader.id}", person: {author: "true"}

      expect(last_response.headers["Location"]).to eq("/login/new")
      expect(book_repo.author?(book: book, user: reader)).to be(false)
    end
  end
end
