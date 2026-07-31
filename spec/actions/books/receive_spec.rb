# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Actions::Books::Receive do
  subject do
    described_class.new(receive_book: receive_book, find_book: find_book)
  end

  let(:book) { double(Twist::Structs::Book, permalink: "exploding-rails") }

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
    let(:receive_book) do
      ->(permalink:, branch_name:, event:, delivery_id:) { Failure(:book_not_found) }
    end

    it "reports back the book cannot be found" do
      status, _, body = subject.(params)
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
end
