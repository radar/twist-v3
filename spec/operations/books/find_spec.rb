# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Operations::Books::Find do
  subject { described_class.new(book_repo: book_repo) }

  let(:book_repo) { instance_double(Twist::Repos::BookRepo) }
  let(:book) { double(Twist::Structs::Book, id: 1, permalink: "exploding-rails") }

  context "when a book with the permalink exists" do
    before do
      allow(book_repo).to receive(:by_permalink).with("exploding-rails").and_return(book)
    end

    it "returns the book" do
      expect(subject.(permalink: "exploding-rails")).to eq(Success(book))
    end
  end

  context "when no book with the permalink exists" do
    before do
      allow(book_repo).to receive(:by_permalink).with("nope").and_return(nil)
    end

    it "returns a failure" do
      expect(subject.(permalink: "nope")).to eq(Failure(:book_not_found))
    end
  end
end
