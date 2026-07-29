# frozen_string_literal: true

RSpec.describe "Invites", :db, type: :request do
  let(:user_repo) { Hanami.app["repos.user_repo"] }
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:invite_repo) { Hanami.app["repos.invite_repo"] }
  let(:invite_mailer) { Hanami.app["mailers.invite"] }

  let(:author) do
    user_repo.create(name: "Author", email: "author@example.com", password: "password123")
  end

  let(:authored_book) do
    book_repo.create(title: "Exploding Rails", permalink: "exploding-rails", format: "markdown")
  end

  let(:other_book) do
    book_repo.create(title: "Someone Else's Book", permalink: "someone-elses-book", format: "markdown")
  end

  before do
    book_repo.grant_permission(book: authored_book, user: author, author: true)
    other_book
    invite_mailer.delivery_method.clear
  end

  def sign_in
    post "/sessions", session: {email: author.email, password: "password123"}
  end

  describe "GET /invites/new" do
    it "redirects when not signed in" do
      get "/invites/new"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/login/new")
    end

    it "lists only the books the current user authors" do
      sign_in
      get "/invites/new"

      expect(last_response).to be_successful
      expect(last_response.body).to include("Exploding Rails")
      expect(last_response.body).not_to include("Someone Else's Book")
    end
  end

  describe "POST /invites" do
    it "creates an invite for the given books and sends the email" do
      sign_in
      post "/invites", invite: {email: "invitee@example.com", book_ids: [authored_book.id.to_s]}

      expect(last_response.status).to eq(302)

      invite = invite_repo.invites.where(email: "invitee@example.com").first
      expect(invite).not_to be_nil
      expect(invite.token).not_to be_nil
      expect(invite.invited_by_id).to eq(author.id)
      expect(invite_repo.books_for(invite).map(&:id)).to eq([authored_book.id])

      deliveries = invite_mailer.delivery_method.deliveries
      expect(deliveries.size).to eq(1)

      settings = Hanami.app["settings"]
      accept_url = "#{settings.base_url}/invites/#{invite.token}"

      message = deliveries.first.message
      expect(message.to).to eq(["invitee@example.com"])
      expect(message.from).to eq([settings.mail_from])
      expect(message.subject).to eq("Author has invited you to Twist")
      expect(message.html_body).to include("Exploding Rails")
      expect(message.html_body).to include(accept_url)
      expect(message.text_body).to include(accept_url)
    end

    it "ignores books the current user does not author" do
      sign_in
      post "/invites", invite: {email: "invitee@example.com", book_ids: [other_book.id.to_s]}

      invite = invite_repo.invites.where(email: "invitee@example.com").first
      expect(invite_repo.books_for(invite)).to be_empty
    end

    it "rejects an email that already has an account" do
      sign_in
      post "/invites", invite: {email: author.email}

      expect(invite_repo.invites.count).to eq(0)
      expect(invite_mailer.delivery_method.deliveries).to be_empty
    end

    it "requires an email address" do
      sign_in
      post "/invites", invite: {email: ""}

      expect(invite_repo.invites.count).to eq(0)
      expect(invite_mailer.delivery_method.deliveries).to be_empty
    end

    it "redirects when not signed in" do
      post "/invites", invite: {email: "invitee@example.com"}

      expect(last_response.headers["Location"]).to eq("/login/new")
      expect(invite_repo.invites.count).to eq(0)
    end
  end

  describe "GET /invites/:token" do
    it "shows the invite" do
      invite = invite_repo.create_for(
        email: "invitee@example.com",
        invited_by: author,
        book_ids: [authored_book.id]
      )

      get "/invites/#{invite.token}"

      expect(last_response).to be_successful
      expect(last_response.body).to include("invitee@example.com")
      expect(last_response.body).to include("Exploding Rails")
    end

    it "redirects to login for an unknown token" do
      get "/invites/nope"

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/login/new")
    end
  end

  describe "POST /invites/:token/accept" do
    let(:invite) do
      invite_repo.create_for(
        email: "invitee@example.com",
        invited_by: author,
        book_ids: [authored_book.id]
      )
    end

    it "creates the user, grants book access and signs them in" do
      post "/invites/#{invite.token}/accept", user: {name: "Invitee", password: "password123"}

      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/")

      user = user_repo.find_by_email("invitee@example.com")
      expect(user).not_to be_nil
      expect(user_repo.authenticate("invitee@example.com", "password123")).not_to be_nil
      expect(book_repo.permitted_for_user(user).map(&:id)).to eq([authored_book.id])
      expect(invite_repo.find_pending_by_token(invite.token)).to be_nil
    end

    it "rejects a short password" do
      post "/invites/#{invite.token}/accept", user: {name: "Invitee", password: "short"}

      expect(user_repo.find_by_email("invitee@example.com")).to be_nil
      expect(invite_repo.find_pending_by_token(invite.token)).not_to be_nil
    end

    it "cannot be accepted twice" do
      post "/invites/#{invite.token}/accept", user: {name: "Invitee", password: "password123"}
      post "/invites/#{invite.token}/accept", user: {name: "Invitee", password: "password123"}

      expect(last_response.headers["Location"]).to eq("/login/new")
      expect(user_repo.users.where(email: "invitee@example.com").count).to eq(1)
    end
  end
end
