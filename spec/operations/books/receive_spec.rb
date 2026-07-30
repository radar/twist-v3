# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Operations::Books::Receive do
  subject do
    described_class.new(
      find_book: find_book,
      find_or_create_branch: find_or_create_branch,
    )
  end

  let(:find_book) do
    ->(permalink:) { Success(book) }
  end

  let(:find_or_create_branch) do
    ->(book_id:, ref:) { Success(branch) }
  end

  let(:branch) { double(Twist::Structs::Branch, name: "master") }

  context "when the book is a markdown book" do
    let(:book) do
      double(
        Twist::Structs::Book,
        id: 1,
        permalink: "exploding-rails",
        format: "markdown",
        github_user: "radar",
        github_repo: "exploding_rails",
      )
    end

    it "enqueues the markdown worker" do
      expect(Twist::Processors::Markdown::BookWorker).to receive(:perform_async)
        .with(
          "permalink" => "exploding-rails",
          "branch" => "master",
          "username" => "radar",
          "repo" => "exploding_rails",
        )

      result = subject.(permalink: "exploding-rails", branch_name: "refs/heads/master")
      expect(result).to be_success
    end
  end

  context "when the book is an asciidoc book" do
    let(:book) do
      double(
        Twist::Structs::Book,
        id: 1,
        permalink: "exploding-rails",
        format: "asciidoc",
        github_user: "radar",
        github_repo: "exploding_rails",
      )
    end

    it "enqueues the asciidoc worker" do
      expect(Twist::Processors::Asciidoc::BookWorker).to receive(:perform_async)
        .with(
          "permalink" => "exploding-rails",
          "branch" => "master",
          "username" => "radar",
          "repo" => "exploding_rails",
        )

      result = subject.(permalink: "exploding-rails", branch_name: "refs/heads/master")
      expect(result).to be_success
    end
  end

  context "when the book cannot be found" do
    let(:book) { nil }

    let(:find_book) do
      ->(permalink:) { Failure(:book_not_found) }
    end

    it "returns a failure without enqueuing any worker" do
      expect(Twist::Processors::Markdown::BookWorker).to_not receive(:perform_async)
      expect(Twist::Processors::Asciidoc::BookWorker).to_not receive(:perform_async)

      result = subject.(permalink: "nope", branch_name: "refs/heads/master")
      expect(result).to eq(Failure(:book_not_found))
    end
  end
end
