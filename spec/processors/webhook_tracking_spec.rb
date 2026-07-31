# frozen_string_literal: true
require "spec_helper"

RSpec.describe Twist::Processors::WebhookTracking do
  subject { worker_class.new(webhook_repo) }

  let(:webhook_repo) { instance_double(Twist::Repos::WebhookRepo) }

  let(:worker_class) do
    Class.new do
      include Twist::Processors::WebhookTracking

      attr_reader :webhook_repo

      def initialize(webhook_repo)
        @webhook_repo = webhook_repo
      end

      def run(webhook_id, &block)
        track_webhook(webhook_id, &block)
      end
    end
  end

  it "marks the webhook's job as running, then succeeded" do
    expect(webhook_repo).to receive(:mark_running).with(7).ordered
    expect(webhook_repo).to receive(:mark_succeeded).with(7).ordered

    expect(subject.run(7) { :processed }).to eq(:processed)
  end

  it "marks the webhook's job as failed and re-raises" do
    expect(webhook_repo).to receive(:mark_running).with(7)
    expect(webhook_repo).to receive(:mark_failed)
      .with(7, error: "RuntimeError: no book.adoc")

    expect {
      subject.run(7) { raise "no book.adoc" }
    }.to raise_error(RuntimeError, "no book.adoc")
  end

  it "runs untracked when the job carries no webhook" do
    expect(webhook_repo).to_not receive(:mark_running)

    expect(subject.run(nil) { :processed }).to eq(:processed)
  end
end
