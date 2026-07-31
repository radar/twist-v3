# frozen_string_literal: true
require "spec_helper"
require "openssl"
require "rack/mock_request"

RSpec.describe Twist::Actions::Books::Receive do
  subject do
    described_class.new(receive_book: receive_book, find_book: find_book)
  end

  let(:secret) { nil }

  let(:book) do
    double(Twist::Structs::Book, permalink: "exploding-rails", webhook_secret: secret)
  end

  let(:find_book) do
    ->(permalink:) { Success(book) }
  end

  let(:receive_book) do
    ->(permalink:, branch_name:, event:, delivery_id:) { Success(true) }
  end

  let(:params) do
    {
      permalink: "exploding-rails",
      payload: {
        ref: "refs/heads/master",
        repository: {
          full_name: "radar/exploding_rails",
        },
      }.to_json,
      "HTTP_X_GITHUB_EVENT" => "push",
      "HTTP_X_GITHUB_DELIVERY" => "delivery-1",
    }
  end

  # The body GitHub actually sends when the webhook uses the content type the
  # setup instructions ask for: the JSON payload urlencoded into a `payload`
  # form field. Signatures are computed over these exact bytes.
  let(:push_payload) do
    {
      ref: "refs/heads/master",
      repository: {full_name: "radar/exploding_rails"}
    }.to_json
  end

  let(:push_body) { "payload=#{Rack::Utils.escape(push_payload)}" }

  def form_env(body:, event: "push", signature: nil, permalink: "exploding-rails")
    env = Rack::MockRequest.env_for(
      "/books/#{permalink}/receive",
      method: "POST",
      input: body,
      "CONTENT_TYPE" => "application/x-www-form-urlencoded"
    )

    env["router.params"] = {permalink: permalink}
    env["HTTP_X_GITHUB_EVENT"] = event
    env["HTTP_X_GITHUB_DELIVERY"] = "delivery-1"
    env["HTTP_X_HUB_SIGNATURE_256"] = signature if signature
    env
  end

  def signature_for(body, key)
    "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", key, body)}"
  end

  # Rack 3 does not promise that `rack.input` is rewindable, and form parsing
  # has already read it by the time the action runs. This stands in for such an
  # input: readable once, and it complains if anything tries to rewind it.
  NonRewindableInput = Class.new do
    def initialize(body)
      @io = StringIO.new(body)
    end

    def read(*args)
      @io.read(*args)
    end

    def gets(*args)
      @io.gets(*args)
    end

    def each(&block)
      @io.each(&block)
    end

    def rewind
      raise IOError, "this input is not rewindable"
    end

    def close
      @io.close
    end
  end

  context "when the book exists" do
    it "hands the book off to the receive operation" do
      expect(receive_book).to receive(:call)
        .with(
          permalink: "exploding-rails",
          branch_name: "refs/heads/master",
          event: "push",
          delivery_id: "delivery-1"
        )
        .and_return(Success(true))

      response = subject.call(params)
      expect(response).to be_successful
    end
  end

  context "when the book does not exist" do
    let(:find_book) do
      ->(permalink:) { Failure(:book_not_found) }
    end

    it "reports back the book cannot be found" do
      status, _, body = subject.(params)
      expect(status).to eq(404)
      expect(JSON.parse(body.first)).to eq("error" => "Book not found")
    end

    it "reports back the book cannot be found even for a signed delivery" do
      status, _, body = subject.(
        form_env(body: push_body, signature: signature_for(push_body, "s3cr3t"))
      )

      expect(status).to eq(404)
      expect(JSON.parse(body.first)).to eq("error" => "Book not found")
    end
  end

  context "when GitHub sends a ping" do
    let(:ping_params) do
      {
        permalink: "exploding-rails",
        "HTTP_X_GITHUB_EVENT" => "ping",
        payload: {
          zen: "Avoid administrative distraction.",
          hook_id: 659323745,
          repository: {
            full_name: "radar/exploding_rails",
          },
        }.to_json
      }
    end

    it "responds with a pong without processing the book" do
      expect(receive_book).to_not receive(:call)

      status, _, body = subject.(ping_params)
      expect(status).to eq(200)
      expect(JSON.parse(body.first)).to eq("message" => "pong")
    end

    context "when the book cannot be found" do
      let(:find_book) do
        ->(permalink:) { Failure(:book_not_found) }
      end

      it "reports back the book cannot be found" do
        status, _, body = subject.(ping_params)
        expect(status).to eq(404)
        expect(JSON.parse(body.first)).to eq("error" => "Book not found")
      end
    end
  end

  # Books that predate signature verification have no secret, and have to keep
  # working exactly as they did.
  context "when the book has no webhook secret" do
    it "accepts an unsigned push" do
      expect(receive_book).to receive(:call).and_return(Success(true))

      status, = subject.(form_env(body: push_body))
      expect(status).to eq(200)
    end

    it "accepts an unsigned ping" do
      expect(receive_book).to_not receive(:call)

      status, _, body = subject.(form_env(body: push_body, event: "ping"))
      expect(status).to eq(200)
      expect(JSON.parse(body.first)).to eq("message" => "pong")
    end
  end

  context "when the book has a webhook secret" do
    let(:secret) { "0123456789abcdef0123456789abcdef01234567" }

    it "accepts a push signed with the secret" do
      expect(receive_book).to receive(:call)
        .with(
          permalink: "exploding-rails",
          branch_name: "refs/heads/master",
          event: "push",
          delivery_id: "delivery-1"
        )
        .and_return(Success(true))

      status, = subject.(
        form_env(body: push_body, signature: signature_for(push_body, secret))
      )

      expect(status).to eq(200)
    end

    it "accepts a ping signed with the secret" do
      ping_body = "payload=#{Rack::Utils.escape({zen: "Keep it logically awesome."}.to_json)}"

      expect(receive_book).to_not receive(:call)

      status, _, body = subject.(
        form_env(
          body: ping_body,
          event: "ping",
          signature: signature_for(ping_body, secret)
        )
      )

      expect(status).to eq(200)
      expect(JSON.parse(body.first)).to eq("message" => "pong")
    end

    it "accepts a signed push whose body cannot be rewound" do
      expect(receive_book).to receive(:call).and_return(Success(true))

      env = form_env(body: push_body, signature: signature_for(push_body, secret))
      env["rack.input"] = NonRewindableInput.new(push_body)

      status, = subject.(env)
      expect(status).to eq(200)
    end

    it "rejects a push signed with the wrong secret" do
      # Nothing downstream may run: the receive operation is what records the
      # webhook row and enqueues the rebuild job.
      expect(receive_book).to_not receive(:call)

      status, _, body = subject.(
        form_env(body: push_body, signature: signature_for(push_body, "not-the-secret"))
      )

      expect(status).to eq(401)
      expect(JSON.parse(body.first)).to eq("error" => "Invalid webhook signature")
    end

    it "rejects a push with no signature header at all" do
      expect(receive_book).to_not receive(:call)

      status, _, body = subject.(form_env(body: push_body))

      expect(status).to eq(401)
      expect(JSON.parse(body.first)).to eq("error" => "Invalid webhook signature")
    end

    it "rejects a malformed signature header" do
      expect(receive_book).to_not receive(:call)

      status, = subject.(form_env(body: push_body, signature: "nonsense"))
      expect(status).to eq(401)

      status, = subject.(form_env(body: push_body, signature: "sha256=short"))
      expect(status).to eq(401)
    end

    it "rejects the legacy SHA-1 signature header" do
      expect(receive_book).to_not receive(:call)

      env = form_env(body: push_body)
      env["HTTP_X_HUB_SIGNATURE"] =
        "sha1=#{OpenSSL::HMAC.hexdigest("SHA1", secret, push_body)}"

      status, = subject.(env)
      expect(status).to eq(401)
    end

    # The signature covers the urlencoded form body, not the JSON inside it. If
    # verification re-serialised the payload instead of using the bytes that
    # arrived, real GitHub deliveries would be rejected.
    it "rejects a signature computed over the payload rather than the raw body" do
      expect(receive_book).to_not receive(:call)

      status, = subject.(
        form_env(body: push_body, signature: signature_for(push_payload, secret))
      )

      expect(status).to eq(401)
    end

    it "rejects a body that has been tampered with after signing" do
      expect(receive_book).to_not receive(:call)

      signature = signature_for(push_body, secret)
      tampered = "payload=#{Rack::Utils.escape({ref: "refs/heads/evil"}.to_json)}"

      status, = subject.(form_env(body: tampered, signature: signature))
      expect(status).to eq(401)
    end

    context "when the book does not exist" do
      let(:find_book) do
        ->(permalink:) { Failure(:book_not_found) }
      end

      it "still reports 404 rather than 401" do
        status, _, body = subject.(
          form_env(body: push_body, permalink: "nope", signature: "sha256=whatever")
        )

        expect(status).to eq(404)
        expect(JSON.parse(body.first)).to eq("error" => "Book not found")
      end
    end
  end
end
