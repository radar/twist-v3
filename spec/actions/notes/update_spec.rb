# frozen_string_literal: true

RSpec.describe Twist::Actions::Notes::Update do
  subject { described_class.new(book_repo: book_repo, note_repo: note_repo, user_repo: user_repo) }

  let(:book_repo) { double("BookRepo") }
  let(:note_repo) { double("NoteRepo") }
  let(:user_repo) { double("UserRepo") }
  let(:book) { double("Book", id: 1, permalink: "book-permalink") }
  let(:user) { double("User", id: 1) }
  let(:note) { double("Note", id: 3, user_id: note_author_id) }
  let(:note_author_id) { user.id }

  # A unit-called action reads its params straight from the Rack env.
  let(:env) do
    {
      book_permalink: "book-permalink",
      chapter_permalink: "chapter-permalink",
      element_id: "2",
      id: "3",
      note: { text: "Updated note text" },
      "rack.session" => { user_id: 1 }
    }
  end

  before do
    allow(user_repo).to receive(:find).and_return(user)
    allow(book_repo).to receive(:find_by_permalink).with("book-permalink").and_return(book)
    allow(book_repo).to receive(:author?).with(book: book, user: user).and_return(author)
    allow(note_repo).to receive(:find_by_book_and_id).with(book, "3").and_return(note)
  end

  context "when the user wrote the note" do
    let(:author) { false }

    it "updates the note" do
      expect(note_repo).to receive(:update).with("3", { text: "Updated note text" })

      response = subject.call(env)

      expect(response.status).to eq(302)
    end
  end

  context "when the user is an author of the book" do
    let(:author) { true }
    let(:note_author_id) { 99 }

    it "updates the note" do
      expect(note_repo).to receive(:update).with("3", { text: "Updated note text" })

      response = subject.call(env)

      expect(response.status).to eq(302)
    end
  end

  context "when the user neither wrote the note nor authors the book" do
    let(:author) { false }
    let(:note_author_id) { 99 }

    it "does not update the note" do
      expect(note_repo).to_not receive(:update)

      response = subject.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books/book-permalink")
    end
  end
end
