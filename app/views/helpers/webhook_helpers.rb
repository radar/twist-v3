# frozen_string_literal: true

module Twist
  module Views
    module Helpers
      module WebhookHelpers
        JOB_STATUS_LABELS = {
          "pending" => "Not queued",
          "enqueued" => "Queued",
          "running" => "Running",
          "succeeded" => "Ran",
          "failed" => "Failed"
        }.freeze

        def webhook_status_label(webhook)
          JOB_STATUS_LABELS.fetch(webhook.job_status, webhook.job_status)
        end

        def webhook_status_class(webhook)
          "webhook-status webhook-status-#{webhook.job_status}"
        end

        # Webhooks store the raw git ref ("refs/heads/main"); the branch is the
        # last segment, which is what the job actually processes.
        def webhook_branch(webhook)
          webhook.ref.to_s.split("/").last
        end

        # How long the job took, once it has both started and finished.
        def webhook_job_duration(webhook)
          return nil unless webhook.job_started_at && webhook.job_finished_at

          seconds = webhook.job_finished_at - webhook.job_started_at
          return "#{(seconds * 1000).round}ms" if seconds < 1

          "#{seconds.round(1)}s"
        end
      end
    end
  end
end
