# frozen_string_literal: true

RSpec.describe Twist::Actions::Notes::Open do
  subject { described_class.new(book_repo: book_repo, note_repo: note_repo, user_repo: user_repo) }

  let(:book_repo) { double("BookRepo") }
  let(:note_repo) { double("NoteRepo") }
  let(:user_repo) { double("UserRepo") }
  let(:book) { double("Book", id: 1, permalink: "book-permalink") }
  let(:user) { double("User", id: 1) }

  # A unit-called action reads its params straight from the Rack env.
  let(:env) do
    {
      book_permalink: "book-permalink",
      chapter_permalink: "chapter-permalink",
      element_id: "2",
      id: "3",
      "rack.session" => { user_id: 1 }
    }
  end

  before do
    allow(user_repo).to receive(:find).and_return(user)
    allow(book_repo).to receive(:find_by_permalink).with("book-permalink").and_return(book)
  end

  context "when the user is an author of the book" do
    before do
      allow(book_repo).to receive(:author?).with(book: book, user: user).and_return(true)
    end

    it "re-opens the note" do
      expect(note_repo).to receive(:open!).with("3")

      response = subject.call(env)

      expect(response.status).to eq(302)
    end
  end

  context "when the user is not an author of the book" do
    before do
      allow(book_repo).to receive(:author?).with(book: book, user: user).and_return(false)
    end

    it "does not re-open the note" do
      expect(note_repo).to_not receive(:open!)

      response = subject.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books/book-permalink")
    end
  end
end
