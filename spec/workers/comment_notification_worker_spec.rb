# frozen_string_literal: true

RSpec.describe Twist::CommentNotificationWorker, :db do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:branch_repo) { Hanami.app["repos.branch_repo"] }
  let(:commit_repo) { Hanami.app["repos.commit_repo"] }
  let(:chapter_repo) { Hanami.app["repos.chapter_repo"] }
  let(:element_repo) { Hanami.app["repos.element_repo"] }
  let(:note_repo) { Hanami.app["repos.note_repo"] }
  let(:comment_repo) { Hanami.app["repos.comment_repo"] }
  let(:mailer) { Hanami.app["mailers.comment_notification"] }
  let(:settings) { Hanami.app["settings"] }

  let(:author) do
    user_repo.create(name: "Author", email: "author@example.com", password: "password123")
  end

  let(:reader) do
    user_repo.create(name: "Reader", email: "reader@example.com", password: "password123")
  end

  let(:other_reader) do
    user_repo.create(name: "Other Reader", email: "other@example.com", password: "password123")
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

  # Left by the reader, so the author is only ever reached as an author of the
  # book rather than as the note's writer.
  let(:note) do
    note_repo.create(
      book_id: book.id,
      element_id: element.id,
      user_id: reader.id,
      text: "Still needs work",
      state: "open",
      number: 4
    )
  end

  def reply(user:, text: "Agreed")
    comment_repo.create(note_id: note.id, user_id: user.id, text: text)
  end

  before do
    book_repo.grant_permission(book: book, user: author, author: true)
    book_repo.grant_permission(book: book, user: reader, author: false)
    book_repo.grant_permission(book: book, user: other_reader, author: false)
    note
    mailer.delivery_method.clear
  end

  it "emails the note's writer and the book's authors" do
    comment = reply(user: other_reader)

    described_class.new.perform(comment.id)

    recipients = mailer.delivery_method.deliveries.map { |d| d.message.to }.flatten
    expect(recipients).to contain_exactly("reader@example.com", "author@example.com")
  end

  it "emails everyone who already replied on the thread" do
    reply(user: other_reader, text: "Same here")
    comment = reply(user: author, text: "Fixed on main")

    described_class.new.perform(comment.id)

    recipients = mailer.delivery_method.deliveries.map { |d| d.message.to }.flatten
    expect(recipients).to contain_exactly("reader@example.com", "other@example.com")
  end

  it "emails a person once however many ways they're in the thread" do
    reply(user: reader, text: "Bumping my own note")
    comment = reply(user: author, text: "On it")

    described_class.new.perform(comment.id)

    recipients = mailer.delivery_method.deliveries.map { |d| d.message.to }.flatten
    expect(recipients).to eq(["reader@example.com"])
  end

  it "describes the reply and links straight at the note" do
    comment = reply(user: author, text: "Rewritten in the next push")

    described_class.new.perform(comment.id)

    note_url = "#{settings.base_url}/books/#{book.permalink}/chapters/#{chapter.permalink}" \
      "/elements/#{element.id}#note-#{note.id}"

    message = mailer.delivery_method.deliveries.first.message
    expect(message.to).to eq(["reader@example.com"])
    expect(message.from).to eq([settings.mail_from])
    expect(message.subject).to eq("New reply to note #4 on Exploding Rails")
    expect(message.html_body).to include("Author")
    expect(message.html_body).to include("Rewritten in the next push")
    expect(message.html_body).to include(note_url)
    expect(message.text_body).to include(note_url)
  end

  it "does nothing when the comment has since been deleted" do
    expect { described_class.new.perform(0) }.not_to raise_error

    expect(mailer.delivery_method.deliveries).to be_empty
  end
end
