# frozen_string_literal: true

require "openssl"

# End-to-end cover for webhook signature verification: these go through the
# real Rack stack, so the body is parsed for `params[:payload]` exactly as it is
# in production, and the signature is checked against the bytes that arrived.
RSpec.describe "Receiving a webhook", :db, type: :request do
  let(:book_repo) { Hanami.app["repos.book_repo"] }
  let(:webhook_repo) { Hanami.app["repos.webhook_repo"] }

  let!(:book) do
    book_repo.create(
      title: "Exploding Rails",
      permalink: "exploding-rails",
      format: "markdown",
      github_user: "radar",
      github_repo: "exploding_rails"
    )
  end

  let(:payload) do
    {
      ref: "refs/heads/master",
      repository: {full_name: "radar/exploding_rails"}
    }.to_json
  end

  # What GitHub sends for the content type the setup instructions ask for.
  let(:body) { "payload=#{Rack::Utils.escape(payload)}" }

  before do
    # The rebuild itself needs Redis and a git clone; neither is the subject here.
    allow(Twist::Processors::Markdown::BookWorker)
      .to receive(:perform_async).and_return("job-1")
  end

  def deliver(signature: nil, event: "push", body: self.body, permalink: book.permalink)
    env = {
      "CONTENT_TYPE" => "application/x-www-form-urlencoded",
      "HTTP_X_GITHUB_EVENT" => event,
      "HTTP_X_GITHUB_DELIVERY" => "delivery-1"
    }
    env["HTTP_X_HUB_SIGNATURE_256"] = signature if signature

    post "/books/#{permalink}/receive", body, env
  end

  def signature_for(signed_body, secret)
    "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, signed_body)}"
  end

  context "when the book has no webhook secret" do
    it "accepts an unsigned delivery and queues the rebuild" do
      deliver

      expect(last_response.status).to eq(200)
      expect(Twist::Processors::Markdown::BookWorker).to have_received(:perform_async)
      expect(webhook_repo.recent_for_book(book).count).to eq(1)
    end
  end

  context "when the book has a webhook secret" do
    let!(:secret) { book_repo.rotate_webhook_secret(book) }

    it "accepts a delivery signed over the raw request body" do
      deliver(signature: signature_for(body, secret))

      expect(last_response.status).to eq(200)
      expect(Twist::Processors::Markdown::BookWorker).to have_received(:perform_async)

      webhook = webhook_repo.recent_for_book(book).first
      expect(webhook.ref).to eq("refs/heads/master")
      expect(webhook.job_status).to eq("enqueued")
    end

    it "answers a signed ping with a pong" do
      ping_body = "payload=#{Rack::Utils.escape({zen: "Keep it logically awesome."}.to_json)}"

      deliver(event: "ping", body: ping_body, signature: signature_for(ping_body, secret))

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq("message" => "pong")
      expect(webhook_repo.recent_for_book(book)).to be_empty
    end

    it "rejects a wrongly signed delivery without recording or queueing anything" do
      deliver(signature: signature_for(body, "not-the-secret"))

      expect(last_response.status).to eq(401)
      expect(JSON.parse(last_response.body)).to eq("error" => "Invalid webhook signature")
      expect(Twist::Processors::Markdown::BookWorker).not_to have_received(:perform_async)
      expect(webhook_repo.recent_for_book(book)).to be_empty
    end

    it "rejects a delivery with no signature header" do
      deliver

      expect(last_response.status).to eq(401)
      expect(Twist::Processors::Markdown::BookWorker).not_to have_received(:perform_async)
      expect(webhook_repo.recent_for_book(book)).to be_empty
    end

    it "rejects an unsigned ping" do
      deliver(event: "ping")

      expect(last_response.status).to eq(401)
    end

    it "still reports an unknown permalink as not found" do
      deliver(permalink: "no-such-book", signature: signature_for(body, secret))

      expect(last_response.status).to eq(404)
      expect(JSON.parse(last_response.body)).to eq("error" => "Book not found")
    end
  end
end
