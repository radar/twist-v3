# frozen_string_literal: true

RSpec.describe "Note comments", :db, type: :request do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:branch_repo) { Hanami.app["repos.branch_repo"] }
  let(:commit_repo) { Hanami.app["repos.commit_repo"] }
  let(:chapter_repo) { Hanami.app["repos.chapter_repo"] }
  let(:element_repo) { Hanami.app["repos.element_repo"] }
  let(:note_repo) { Hanami.app["repos.note_repo"] }
  let(:comment_repo) { Hanami.app["repos.comment_repo"] }
  let(:comments) { Hanami.app["relations.comments"] }

  let(:author) do
    user_repo.create(name: "Author", email: "author@example.com", password: "password123")
  end

  let(:reader) do
    user_repo.create(name: "Reader", email: "reader@example.com", password: "password123")
  end

  let(:stranger) do
    user_repo.create(name: "Stranger", email: "stranger@example.com", password: "password123")
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

  # A note left by the author, so the specs also prove a reader can reply to
  # someone else's note.
  let(:note) do
    note_repo.create(
      book_id: book.id,
      element_id: element.id,
      user_id: author.id,
      text: "Still needs work",
      state: "open",
      number: 1
    )
  end

  let(:element_path) do
    "/books/#{book.permalink}/chapters/#{chapter.permalink}/elements/#{element.id}"
  end

  let(:comments_path) { "#{element_path}/notes/#{note.id}/comments" }

  def sign_in(user)
    post "/sessions", session: {email: user.email, password: "password123"}
  end

  before do
    book_repo.grant_permission(book: book, user: author, author: true)
    book_repo.grant_permission(book: book, user: reader, author: false)
    note
  end

  describe "a reader with access to the book" do
    before { sign_in(reader) }

    it "shows the comment form on the element page" do
      get element_path

      expect(last_response).to be_successful
      expect(last_response.body).to include("Reply to this note")
      expect(last_response.body).to include(%(action="#{comments_path}"))
    end

    it "shows the comment form on the book-wide notes page too" do
      get "/books/#{book.permalink}/notes"

      expect(last_response).to be_successful
      expect(last_response.body).to include("Reply to this note")
      expect(last_response.body).to include(%(action="#{comments_path}"))
    end

    it "keeps the reply form inside the notes frame" do
      get element_path

      expect(last_response.body).to include(%(action="#{comments_path}"))
      expect(last_response.body).to_not include(%(data-turbo-frame="_top" class="note-comment-form"))
      expect(last_response.body).to_not include(%(class="note-comment-form" data-turbo-frame="_top"))
    end

    # Replying from a chapter posts from inside `element_notes_<id>`, so Turbo
    # follows the redirect with that frame's name and swaps only the frame. The
    # comment has to come back in that fragment, or the reader loses their place.
    it "returns the new comment inside the notes frame Turbo asked for" do
      post comments_path, comment: {text: "I ran into this too"}

      get element_path, {}, {"HTTP_TURBO_FRAME" => "element_notes_#{element.id}"}

      expect(last_response).to be_successful
      expect(last_response.body).to include(%(<turbo-frame id="element_notes_#{element.id}"))
      frame = last_response.body[/<turbo-frame id="element_notes_#{element.id}".*?<\/turbo-frame>/m]
      expect(frame).to include("I ran into this too")
      expect(frame).to include("Comment added successfully.")
    end

    it "surfaces a blank-comment error inside the notes frame" do
      post comments_path, comment: {text: "   "}

      get element_path, {}, {"HTTP_TURBO_FRAME" => "element_notes_#{element.id}"}

      frame = last_response.body[/<turbo-frame id="element_notes_#{element.id}".*?<\/turbo-frame>/m]
      expect(frame).to include("Your comment needs some text before it can be saved.")
    end

    it "still shows the flash outside the frame on a full page load" do
      post comments_path, comment: {text: "I ran into this too"}

      get element_path

      body = last_response.body
      frame = body[/<turbo-frame id="element_notes_#{element.id}".*?<\/turbo-frame>/m]
      expect(body).to include("Comment added successfully.")
      expect(frame).to_not include("Comment added successfully.")
    end

    it "posts a comment and sees it rendered on the note" do
      post comments_path, comment: {text: "I ran into this too"}

      expect(last_response.status).to eq(303)
      expect(last_response.headers["Location"]).to eq(element_path)

      get element_path

      expect(last_response).to be_successful
      expect(last_response.body).to include("I ran into this too")
      expect(last_response.body).to include(%(data-test-class="comment"))
      expect(last_response.body).to include("Reader")
    end

    it "stays on the book-wide notes page when the reply came from there" do
      notes_path = "/books/#{book.permalink}/notes"

      post comments_path, comment: {text: "I ran into this too"}, return_to: notes_path

      expect(last_response.status).to eq(303)
      expect(last_response.headers["Location"]).to eq(notes_path)
    end

    it "shows the comment on the book-wide notes page as well" do
      post comments_path, comment: {text: "I ran into this too"}

      get "/books/#{book.permalink}/notes"

      expect(last_response.body).to include("I ran into this too")
    end

    it "does not create a comment when the text is blank" do
      post comments_path, comment: {text: "   "}

      expect(comments.count).to eq(0)
      expect(last_response.status).to eq(303)
      expect(last_response.headers["Location"]).to eq(element_path)
    end

    it "does not create a comment when the text is missing entirely" do
      post comments_path

      expect(comments.count).to eq(0)
    end
  end

  describe "a user with no permission on the book" do
    before { sign_in(stranger) }

    it "is rejected and no comment is created" do
      post comments_path, comment: {text: "Let me in"}

      expect(comments.count).to eq(0)
      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
    end

    it "is not offered the comment form" do
      get element_path

      expect(last_response).to be_successful
      expect(last_response.body).not_to include("Reply to this note")
    end
  end

  describe "a visitor who is not signed in" do
    it "is rejected and no comment is created" do
      post comments_path, comment: {text: "Anonymous reply"}

      expect(comments.count).to eq(0)
      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
    end

    it "is not offered the comment form" do
      get element_path

      expect(last_response).to be_successful
      expect(last_response.body).not_to include("Reply to this note")
    end
  end

  describe "a note belonging to another book" do
    let(:other_book) do
      book_repo.create(title: "Exploding Hanami", permalink: "exploding-hanami", format: "markdown")
    end

    let(:other_branch) { branch_repo.create(book_id: other_book.id, name: "main", default: true) }

    let(:other_commit) do
      commit_repo.create(branch_id: other_branch.id, sha: "def456", message: "First commit")
    end

    let(:other_chapter) do
      chapter_repo.create(
        commit_id: other_commit.id,
        title: "Slices",
        permalink: "slices",
        position: 1,
        part: "mainmatter",
        file_name: "slices.md"
      )
    end

    let(:other_element) do
      element_repo.create(chapter_id: other_chapter.id, tag: "p", content: "<p>Slices are neat.</p>")
    end

    let(:other_note) do
      note_repo.create(
        book_id: other_book.id,
        element_id: other_element.id,
        user_id: author.id,
        text: "A note on someone else's book",
        state: "open",
        number: 1
      )
    end

    before do
      other_note
      sign_in(reader)
    end

    it "is rejected even though the reader may comment on this book" do
      post "#{element_path}/notes/#{other_note.id}/comments", comment: {text: "Wrong book"}

      expect(comments.count).to eq(0)
      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
    end
  end

  describe "an author of the book" do
    before { sign_in(author) }

    it "can reply to a note as well" do
      post comments_path, comment: {text: "Thanks, fixed in the next commit"}

      expect(last_response.status).to eq(303)
      expect(comments.count).to eq(1)
    end
  end
end
