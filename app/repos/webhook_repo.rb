# frozen_string_literal: true

require "default_timestamps"

module Twist
  module Repos
    class WebhookRepo < Twist::DB::Repo
      commands :create, use: :default_timestamps

      # Records that a webhook arrived, before any job has been enqueued for it.
      def record_received(book:, event: nil, ref: nil, delivery_id: nil)
        create(
          book_id: book.id,
          event: event,
          ref: ref,
          delivery_id: delivery_id,
          received_at: Time.now.utc,
          job_status: "pending"
        )
      end

      def find(id)
        webhooks.where(id: id).first
      end

      def mark_enqueued(id, job_id:)
        update(id, job_status: "enqueued", job_id: job_id)
      end

      def mark_running(id)
        update(id, job_status: "running", job_started_at: Time.now.utc)
      end

      def mark_succeeded(id)
        update(id, job_status: "succeeded", job_finished_at: Time.now.utc, job_error: nil)
      end

      def mark_failed(id, error:)
        update(id, job_status: "failed", job_finished_at: Time.now.utc, job_error: error)
      end

      # Most recently received webhooks for a book, newest first.
      def recent_for_book(book, limit: 25)
        webhooks
          .where(book_id: book.id)
          .order { [received_at.desc, id.desc] }
          .limit(limit)
          .to_a
      end

      private

      def update(id, attributes)
        webhooks.where(id: id).update(attributes.merge(updated_at: Time.now.utc))
      end
    end
  end
end
