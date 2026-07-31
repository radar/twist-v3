# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Repos::WebhookRepo do
  subject(:webhook_repo) { described_class.new }

  let(:book_repo) { Twist::Repos::BookRepo.new }

  let(:book) do
    book_repo.create(title: "Exploding Rails", permalink: "exploding-rails", format: "markdown")
  end

  it "records a received webhook with no job yet" do
    webhook = webhook_repo.record_received(
      book: book,
      event: "push",
      ref: "refs/heads/main",
      delivery_id: "delivery-1"
    )

    expect(webhook.book_id).to eq(book.id)
    expect(webhook.event).to eq("push")
    expect(webhook.ref).to eq("refs/heads/main")
    expect(webhook.delivery_id).to eq("delivery-1")
    expect(webhook.received_at).to_not be_nil
    expect(webhook.job_status).to eq("pending")
    expect(webhook.job_id).to be_nil
  end

  it "tracks a job through to success" do
    webhook = webhook_repo.record_received(book: book, ref: "refs/heads/main")

    webhook_repo.mark_enqueued(webhook.id, job_id: "jid-1")
    expect(webhook_repo.find(webhook.id).job_status).to eq("enqueued")
    expect(webhook_repo.find(webhook.id).job_id).to eq("jid-1")

    webhook_repo.mark_running(webhook.id)
    running = webhook_repo.find(webhook.id)
    expect(running.job_status).to eq("running")
    expect(running.job_started_at).to_not be_nil

    webhook_repo.mark_succeeded(webhook.id)
    succeeded = webhook_repo.find(webhook.id)
    expect(succeeded.job_status).to eq("succeeded")
    expect(succeeded.job_finished_at).to_not be_nil
    expect(succeeded.job_error).to be_nil
  end

  it "tracks a failed job with its error" do
    webhook = webhook_repo.record_received(book: book, ref: "refs/heads/main")

    webhook_repo.mark_failed(webhook.id, error: "RuntimeError: unknown format")

    failed = webhook_repo.find(webhook.id)
    expect(failed.job_status).to eq("failed")
    expect(failed.job_error).to eq("RuntimeError: unknown format")
    expect(failed.job_finished_at).to_not be_nil
  end

  describe "#recent_for_book" do
    let(:other_book) do
      book_repo.create(title: "Other Book", permalink: "other-book", format: "markdown")
    end

    it "returns the book's webhooks, newest first" do
      older = webhook_repo.record_received(book: book, delivery_id: "older")
      newer = webhook_repo.record_received(book: book, delivery_id: "newer")
      webhook_repo.record_received(book: other_book, delivery_id: "elsewhere")

      delivery_ids = webhook_repo.recent_for_book(book).map(&:delivery_id)

      expect(delivery_ids).to eq(["newer", "older"])
      expect(newer.id).to be > older.id
    end

    it "caps how many it returns" do
      3.times { |i| webhook_repo.record_received(book: book, delivery_id: "delivery-#{i}") }

      expect(webhook_repo.recent_for_book(book, limit: 2).count).to eq(2)
    end
  end
end
