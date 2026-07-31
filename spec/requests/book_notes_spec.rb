# frozen_string_literal: true

RSpec.describe "Book notes", :db, type: :request do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:branch_repo) { Hanami.app["repos.branch_repo"] }
  let(:commit_repo) { Hanami.app["repos.commit_repo"] }
  let(:chapter_repo) { Hanami.app["repos.chapter_repo"] }
  let(:element_repo) { Hanami.app["repos.element_repo"] }
  let(:note_repo) { Hanami.app["repos.note_repo"] }

  let(:author) do
    user_repo.create(name: "Author", email: "author@example.com", password: "password123")
  end

  let(:book) do
    book_repo.create(title: "Exploding Rails", permalink: "exploding-rails", format: "markdown")
  end

  let(:branch) { branch_repo.create(book_id: book.id, name: "main", default: true) }
  let(:commit) { commit_repo.create(branch_id: branch.id, sha: "abc123", message: "First commit") }

  let(:chapter) do
    chapter_repo.create(
      commit_id: commit.id,
      title: "Pairing",
      permalink: "pairing",
      position: 1,
      part: "mainmatter",
      file_name: "pairing.md"
    )
  end

  let(:element) do
    element_repo.create(chapter_id: chapter.id, tag: "p", content: "<p>Pairing is a super power.</p>")
  end

  def create_note(text:, state:, number:, on: element)
    note_repo.create(
      book_id: book.id,
      element_id: on.id,
      user_id: author.id,
      text: text,
      state: state,
      number: number
    )
  end

  before do
    book_repo.grant_permission(book: book, user: author, author: true)
    element
    create_note(text: "Still needs work", state: "open", number: 1)
    create_note(text: "Fixed in review", state: "closed", number: 2)
    create_note(text: "From before the state column", state: nil, number: 3)

    post "/sessions", session: {email: author.email, password: "password123"}
  end

  describe "notes left against an earlier commit" do
    let(:second_commit) do
      commit_repo.create(branch_id: branch.id, sha: "def456", message: "Second commit")
    end

    let(:second_chapter) do
      chapter_repo.create(
        commit_id: second_commit.id,
        title: "Pairing",
        permalink: "pairing",
        position: 1,
        part: "mainmatter",
        file_name: "pairing.md"
      )
    end

    let(:second_element) do
      element_repo.create(
        chapter_id: second_chapter.id,
        tag: "p",
        content: "<p>Pairing is still a super power.</p>"
      )
    end

    before do
      second_element
      create_note(text: "Left on the newest commit", state: "open", number: 4, on: second_element)
    end

    it "lists notes from every commit of the book" do
      get "/books/#{book.permalink}/notes"

      expect(last_response).to be_successful
      expect(last_response.body).to include("Left on the newest commit")
      expect(last_response.body).to include("Still needs work")
      expect(last_response.body).to include("From before the state column")
    end

    it "counts them all on the tabs" do
      get "/books/#{book.permalink}/notes"

      expect(last_response.body).to include("notes-tab-count\">3")
      expect(last_response.body).to include("notes-tab-count\">1")
    end

    it "links a superseded element back to its own commit" do
      get "/books/#{book.permalink}/notes"

      expect(last_response.body).to include(
        "/books/#{book.permalink}/chapters/pairing/elements/#{element.id}"
      )

      get "/books/#{book.permalink}/chapters/pairing/elements/#{element.id}"

      expect(last_response).to be_successful
      expect(last_response.body).to include("Pairing is a super power.")
      expect(last_response.body).to include("abc123")
    end
  end

  describe "GET /books/:book_permalink/notes" do
    it "lists the open notes, counting stateless notes as open" do
      get "/books/#{book.permalink}/notes"

      expect(last_response).to be_successful
      expect(last_response.body).to include("Still needs work")
      expect(last_response.body).to include("From before the state column")
      expect(last_response.body).not_to include("Fixed in review")
    end

    it "shows both counts on the tabs" do
      get "/books/#{book.permalink}/notes"

      expect(last_response.body).to include("notes-tab-count\">2")
      expect(last_response.body).to include("notes-tab-count\">1")
    end
  end

  describe "GET /books/:book_permalink/notes?status=closed" do
    it "lists only the closed notes" do
      get "/books/#{book.permalink}/notes?status=closed"

      expect(last_response).to be_successful
      expect(last_response.body).to include("Closed notes")
      expect(last_response.body).to include("Fixed in review")
      expect(last_response.body).not_to include("Still needs work")
    end

    it "offers to re-open them" do
      get "/books/#{book.permalink}/notes?status=closed"

      expect(last_response.body).to include("Re-open")
    end

    it "falls back to the open notes for an unknown status" do
      get "/books/#{book.permalink}/notes?status=banana"

      expect(last_response.body).to include("Still needs work")
      expect(last_response.body).not_to include("Fixed in review")
    end
  end
end
