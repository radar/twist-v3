# frozen_string_literal: true

RSpec.describe "Webhooks", :db, type: :request do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:webhook_repo) { Hanami.app["repos.webhook_repo"] }

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

  describe "GET /books/:book_permalink/webhooks" do
    it "redirects when not signed in" do
      get "/books/#{book.permalink}/webhooks"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/login/new")
    end

    it "redirects a non-author back to the book" do
      sign_in(reader)
      get "/books/#{book.permalink}/webhooks"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
    end

    it "explains the setup and shows the receive URL" do
      sign_in(author)
      get "/books/#{book.permalink}/webhooks"

      expect(last_response).to be_successful
      expect(last_response.body).to include("http://localhost:2300/books/exploding-rails/receive")
      expect(last_response.body).to include("application/x-www-form-urlencoded")
      expect(last_response.body).to include("Just the push event")
    end

    it "says unsigned deliveries are accepted while there is no secret" do
      sign_in(author)
      get "/books/#{book.permalink}/webhooks"

      expect(last_response.body).to include("This book has no webhook secret")
      expect(last_response.body).to include("Generate a secret")
      expect(last_response.body).to include("Leave <strong>Secret</strong> empty for now")
    end

    it "shows the secret to an author so they can paste it into GitHub" do
      secret = book_repo.rotate_webhook_secret(book)

      sign_in(author)
      get "/books/#{book.permalink}/webhooks"

      expect(last_response.body).to include(secret)
      expect(last_response.body).to include("Paste the secret above into")
      expect(last_response.body).not_to include("This book has no webhook secret")
    end

    it "says so when nothing has been received yet" do
      sign_in(author)
      get "/books/#{book.permalink}/webhooks"

      expect(last_response.body).to include("No webhooks have been received for this book yet")
    end

    it "lists received webhooks for this book with their job outcome" do
      pending_hook = webhook_repo.record_received(
        book: book,
        event: "push",
        ref: "refs/heads/main",
        delivery_id: "aaaaaaaa-1111"
      )

      ran = webhook_repo.record_received(
        book: book,
        event: "push",
        ref: "refs/heads/some-branch",
        delivery_id: "bbbbbbbb-2222"
      )
      webhook_repo.mark_enqueued(ran.id, job_id: "jid-ran")
      webhook_repo.mark_running(ran.id)
      webhook_repo.mark_succeeded(ran.id)

      failed = webhook_repo.record_received(book: book, event: "push", ref: "refs/heads/main")
      webhook_repo.mark_enqueued(failed.id, job_id: "jid-failed")
      webhook_repo.mark_failed(failed.id, error: "RuntimeError: unknown format")

      webhook_repo.record_received(
        book: other_book,
        event: "push",
        ref: "refs/heads/main",
        delivery_id: "cccccccc-3333"
      )

      sign_in(author)
      get "/books/#{book.permalink}/webhooks"

      expect(last_response.body).to include("aaaaaaaa")
      expect(last_response.body).to include("some-branch")
      expect(last_response.body).to include("webhook-status-pending")
      expect(last_response.body).to include("webhook-status-succeeded")
      expect(last_response.body).to include("webhook-status-failed")
      expect(last_response.body).to include("jid-ran")
      expect(last_response.body).to include("RuntimeError: unknown format")

      # Only this book's webhooks.
      expect(last_response.body).not_to include("cccccccc")

      expect(pending_hook.job_status).to eq("pending")
    end
  end

  describe "POST /books/:book_permalink/webhooks/secret" do
    it "redirects when not signed in" do
      post "/books/#{book.permalink}/webhooks/secret"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/login/new")
      expect(book_repo.webhook_secret_for(book)).to be_nil
    end

    it "does not let a non-author rotate the secret" do
      sign_in(reader)
      post "/books/#{book.permalink}/webhooks/secret"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}")
      expect(book_repo.webhook_secret_for(book)).to be_nil
    end

    it "generates a secret for an author and shows it on the webhooks page" do
      sign_in(author)
      post "/books/#{book.permalink}/webhooks/secret"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/books/#{book.permalink}/webhooks")

      secret = book_repo.webhook_secret_for(book)
      expect(secret).to match(/\A[0-9a-f]{40}\z/)

      follow_redirect!
      expect(last_response.body).to include(secret)
      expect(last_response.body).to include("Webhook secret generated")
    end

    it "replaces an existing secret when rotated" do
      original = book_repo.rotate_webhook_secret(book)

      sign_in(author)
      post "/books/#{book.permalink}/webhooks/secret"

      rotated = book_repo.webhook_secret_for(book)
      expect(rotated).not_to eq(original)
      expect(rotated).to match(/\A[0-9a-f]{40}\z/)

      follow_redirect!
      expect(last_response.body).to include(rotated)
      expect(last_response.body).not_to include(original)
      expect(last_response.body).to include("New webhook secret generated")
    end
  end
end
