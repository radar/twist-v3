# frozen_string_literal: true

RSpec.describe Twist::Actions::Comments::Create do
  subject do
    described_class.new(
      book_repo: book_repo,
      note_repo: note_repo,
      comment_repo: comment_repo,
      user_repo: user_repo
    )
  end

  let(:book_repo) { double("BookRepo") }
  let(:note_repo) { double("NoteRepo") }
  let(:comment_repo) { double("CommentRepo") }
  let(:user_repo) { double("UserRepo") }
  let(:book) { double("Book", id: 1, permalink: "book-permalink") }
  let(:note) { double("Note", id: 3) }
  let(:user) { double("User", id: 1) }

  # A unit-called action reads its params straight from the Rack env.
  let(:env) do
    {
      book_permalink: "book-permalink",
      chapter_permalink: "chapter-permalink",
      element_id: "2",
      id: "3",
      comment: {text: "A reply"},
      "rack.session" => {user_id: 1}
    }
  end

  let(:element_path) do
    "/books/book-permalink/chapters/chapter-permalink/elements/2"
  end

  before do
    allow(user_repo).to receive(:find).and_return(user)
    allow(book_repo).to receive(:by_permalink).with("book-permalink").and_return(book)
  end

  context "when the user has access to the book" do
    before do
      allow(book_repo).to receive(:permitted?).with(book: book, user: user).and_return(true)
      allow(note_repo).to receive(:find_by_book_and_id).with(book, 3).and_return(note)
    end

    it "creates the comment and redirects back to the element" do
      expect(comment_repo).to receive(:create).with(
        note_id: 3,
        user_id: 1,
        text: "A reply"
      ).and_return(double("Comment", id: 9))

      response = subject.call(env)

      # 303 so Turbo re-issues the follow-up request as a GET
      expect(response.status).to eq(303)
      expect(response.headers["Location"]).to eq(element_path)
    end

    it "queues the notification email for the new comment" do
      allow(comment_repo).to receive(:create).and_return(double("Comment", id: 9))

      subject.call(env)

      expect(Twist::CommentNotificationWorker.jobs.map { |job| job["args"] }).to eq([[9]])
    end
  end

  context "when the user has no access to the book" do
    before do
      allow(book_repo).to receive(:permitted?).with(book: book, user: user).and_return(false)
    end

    it "does not create the comment" do
      expect(comment_repo).to_not receive(:create)
      expect(note_repo).to_not receive(:find_by_book_and_id)

      response = subject.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books/book-permalink")
    end
  end

  context "when the note belongs to another book" do
    before do
      allow(book_repo).to receive(:permitted?).with(book: book, user: user).and_return(true)
      allow(note_repo).to receive(:find_by_book_and_id).with(book, 3).and_return(nil)
    end

    it "does not create the comment" do
      expect(comment_repo).to_not receive(:create)

      response = subject.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books/book-permalink")
    end
  end

  context "when the comment text is blank" do
    before do
      allow(book_repo).to receive(:permitted?).with(book: book, user: user).and_return(true)
    end

    it "does not create the comment and redirects back to the element" do
      expect(comment_repo).to_not receive(:create)

      response = subject.call(env.merge(comment: {text: "  "}))

      expect(response.status).to eq(303)
      expect(response.headers["Location"]).to eq(element_path)
    end
  end

  context "when the comment params are missing" do
    before do
      allow(book_repo).to receive(:permitted?).with(book: book, user: user).and_return(true)
    end

    it "does not create the comment and redirects back to the element" do
      expect(comment_repo).to_not receive(:create)

      response = subject.call(env.reject { |key, _| key == :comment })

      expect(response.status).to eq(303)
      expect(response.headers["Location"]).to eq(element_path)
    end
  end

  context "when the book does not exist" do
    before do
      allow(book_repo).to receive(:by_permalink).with("book-permalink").and_return(nil)
    end

    it "does not create the comment" do
      expect(comment_repo).to_not receive(:create)

      response = subject.call(env)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books")
    end
  end
end
