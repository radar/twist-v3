# frozen_string_literal: true

RSpec.describe "Inline notes", :db, type: :request do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:branch_repo) { Hanami.app["repos.branch_repo"] }
  let(:commit_repo) { Hanami.app["repos.commit_repo"] }
  let(:chapter_repo) { Hanami.app["repos.chapter_repo"] }
  let(:element_repo) { Hanami.app["repos.element_repo"] }

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

  before do
    book_repo.grant_permission(book: book, user: reader, author: false)
    element
    post "/sessions", session: {email: reader.email, password: "password123"}
  end

  describe "GET the chapter page" do
    before { get "/books/#{book.permalink}/chapters/#{chapter.permalink}" }

    it "gives each paragraph an empty frame for its note panel" do
      expect(last_response).to be_successful
      expect(last_response.body).to include(
        %(<turbo-frame id="element_notes_#{element.id}" class="element-notes"></turbo-frame>)
      )
    end

    it "points the note pill at that frame and marks it toggleable" do
      expect(last_response.body).to include(%(data-turbo-frame="element_notes_#{element.id}"))
      expect(last_response.body).to include("data-note-toggle")
      expect(last_response.body).to include(%(aria-expanded="false"))
    end

    it "still links to the element page so the pill works without Turbo" do
      expect(last_response.body).to include(
        %(href='/books/#{book.permalink}/chapters/#{chapter.permalink}/elements/#{element.id}')
      )
    end
  end

  describe "GET the element page" do
    before do
      get "/books/#{book.permalink}/chapters/#{chapter.permalink}/elements/#{element.id}"
    end

    it "wraps the note panel in the frame the pill targets" do
      expect(last_response).to be_successful
      expect(last_response.body).to include(%(<turbo-frame id="element_notes_#{element.id}"))
      expect(last_response.body).to include("Leave a note")
    end

    it "leaves the pill as a plain link, since the panel is already on the page" do
      expect(last_response.body).to_not include("data-note-toggle")
    end
  end

  describe "POST a note from inside the frame" do
    it "redirects with a 303 so Turbo re-renders the frame with a GET" do
      post(
        "/books/#{book.permalink}/chapters/#{chapter.permalink}/elements/#{element.id}/notes",
        note: {text: "A note"}
      )

      expect(last_response.status).to eq(303)
      expect(last_response.headers["Location"]).to eq(
        "/books/#{book.permalink}/chapters/#{chapter.permalink}/elements/#{element.id}"
      )
    end

    it "queues the notification email for the book's authors" do
      post(
        "/books/#{book.permalink}/chapters/#{chapter.permalink}/elements/#{element.id}/notes",
        note: {text: "A note"}
      )

      note = Hanami.app["relations.notes"].where(element_id: element.id).first
      expect(Twist::NoteNotificationWorker.jobs.map { |job| job["args"] }).to eq([[note[:id]]])
    end
  end
end
