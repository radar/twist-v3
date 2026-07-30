# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Actions::Books::Receive do
  subject do
    described_class.new(receive_book: receive_book)
  end

  let(:params) do
    {
      permalink: "exploding-rails",
      payload: {
        ref: "refs/heads/master",
        repository: {
          full_name: "radar/exploding_rails",
        },
      }.to_json
    }
  end

  context "when the book exists" do
    let(:receive_book) do
      ->(permalink:, branch_name:) { Success(true) }
    end

    it "hands the book off to the receive operation" do
      expect(receive_book).to receive(:call)
        .with(permalink: "exploding-rails", branch_name: "refs/heads/master")
        .and_return(Success(true))

      response = subject.call(params)
      expect(response).to be_successful
    end
  end

  context "when the book does not exist" do
    let(:receive_book) do
      ->(permalink:, branch_name:) { Failure(:book_not_found) }
    end

    it "reports back the book cannot be found" do
      status, _, body = subject.(params)
      expect(status).to eq(404)
      expect(JSON.parse(body.first)).to eq("error" => "Book not found")
    end
  end
end
