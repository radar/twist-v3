# frozen_string_literal: true

RSpec.describe Twist::Actions::Notes::Update do
  let(:params) do
    {
      book_permalink: "book-permalink",
      chapter_permalink: "chapter-permalink",
      note_id: 1,
      text: "Updated note text",

    }
  end
  let(:book_repo) { double("BookRepo") }
  let(:note_repo) { double("NoteRepo") }
  let(:user_repo) { double("UserRepo") }
  let(:book) { double("Book", permalink: "book-permalink") }
  let(:user) { double("User", id: 1) }
  let(:subject) { described_class.new(book_repo: book_repo, note_repo: note_repo, user_repo: user_repo) }

  before do
    allow(user_repo).to receive(:find).with(1).and_return(user)
  end

  it "works" do
    expect(book_repo).to receive(:find_by_permalink).with("book-permalink").and_return(book)
    expect(book_repo).to receive(:permitted?).with(book: book, user: user).and_return(true)
    expect(note_repo).to receive(:update).with(1, { text: "Updated note text" }).and_return(true)
    response = subject.call(params:, session: { user_id: 1 })
    expect(response).to be_successful
  end
end
