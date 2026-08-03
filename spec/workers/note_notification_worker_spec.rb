# frozen_string_literal: true

RSpec.describe Twist::NoteNotificationWorker, :db do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:branch_repo) { Hanami.app["repos.branch_repo"] }
  let(:commit_repo) { Hanami.app["repos.commit_repo"] }
  let(:chapter_repo) { Hanami.app["repos.chapter_repo"] }
  let(:element_repo) { Hanami.app["repos.element_repo"] }
  let(:note_repo) { Hanami.app["repos.note_repo"] }
  let(:mailer) { Hanami.app["mailers.note_notification"] }
  let(:settings) { Hanami.app["settings"] }

  let(:author) do
    user_repo.create(name: "Author", email: "author@example.com", password: "password123")
  end

  let(:co_author) do
    user_repo.create(name: "Co Author", email: "co-author@example.com", password: "password123")
  end

  let(:reader) do
    user_repo.create(name: "Reader", email: "reader@example.com", password: "password123")
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

  def leave_note(user:, text: "Still needs work")
    note_repo.create(
      book_id: book.id,
      element_id: element.id,
      user_id: user.id,
      text: text,
      state: "open",
      number: 1
    )
  end

  before do
    book_repo.grant_permission(book: book, user: author, author: true)
    book_repo.grant_permission(book: book, user: co_author, author: true)
    book_repo.grant_permission(book: book, user: reader, author: false)
    element
    mailer.delivery_method.clear
  end

  it "emails every author when a reader leaves a note" do
    note = leave_note(user: reader)

    described_class.new.perform(note.id)

    deliveries = mailer.delivery_method.deliveries
    expect(deliveries.map { |d| d.message.to }.flatten).to contain_exactly(
      "author@example.com", "co-author@example.com"
    )
  end

  it "describes the note and links straight at it" do
    note = leave_note(user: reader, text: "This paragraph contradicts chapter 2")

    described_class.new.perform(note.id)

    note_url = "#{settings.base_url}/books/#{book.permalink}/chapters/#{chapter.permalink}" \
      "/elements/#{element.id}#note-#{note.id}"

    message = mailer.delivery_method.deliveries.first.message
    expect(message.from).to eq([settings.mail_from])
    expect(message.subject).to eq("New note on Exploding Rails")
    expect(message.html_body).to include("Reader")
    expect(message.html_body).to include("Pairing")
    expect(message.html_body).to include("This paragraph contradicts chapter 2")
    expect(message.html_body).to include(note_url)
    expect(message.text_body).to include(note_url)
  end

  it "does not email the author who left the note themselves" do
    note = leave_note(user: author)

    described_class.new.perform(note.id)

    recipients = mailer.delivery_method.deliveries.map { |d| d.message.to }.flatten
    expect(recipients).to eq(["co-author@example.com"])
  end

  it "does nothing when the note has since been deleted" do
    expect { described_class.new.perform(0) }.not_to raise_error

    expect(mailer.delivery_method.deliveries).to be_empty
  end
end
