# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Operations::Books::Receive do
  subject do
    described_class.new(
      find_book: find_book,
      find_or_create_branch: find_or_create_branch,
      webhook_repo: webhook_repo,
    )
  end

  let(:find_book) do
    ->(permalink:) { Success(book) }
  end

  let(:find_or_create_branch) do
    ->(book_id:, ref:) { Success(branch) }
  end

  let(:branch) { double(Twist::Structs::Branch, name: "master") }

  let(:webhook) { double(id: 99) }

  let(:webhook_repo) do
    instance_double(Twist::Repos::WebhookRepo, record_received: webhook, mark_enqueued: nil)
  end

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
          "webhook_id" => 99,
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
          "webhook_id" => 99,
        )

      result = subject.(permalink: "exploding-rails", branch_name: "refs/heads/master")
      expect(result).to be_success
    end

    it "records the webhook and the job it enqueued" do
      allow(Twist::Processors::Asciidoc::BookWorker).to receive(:perform_async).and_return("jid-1")

      expect(webhook_repo).to receive(:record_received).with(
        book: book,
        event: "push",
        ref: "refs/heads/master",
        delivery_id: "delivery-1"
      ).and_return(webhook)

      expect(webhook_repo).to receive(:mark_enqueued).with(99, job_id: "jid-1")

      subject.(
        permalink: "exploding-rails",
        branch_name: "refs/heads/master",
        event: "push",
        delivery_id: "delivery-1"
      )
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
      expect(webhook_repo).to_not receive(:record_received)

      result = subject.(permalink: "nope", branch_name: "refs/heads/master")
      expect(result).to eq(Failure(:book_not_found))
    end
  end
end
