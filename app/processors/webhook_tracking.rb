# auto_register: false
# frozen_string_literal: true

module Twist
  module Processors
    # Records the progress of a book worker against the webhook that triggered
    # it, so the book's webhook page can show whether a job ran.
    #
    # Including classes need a `webhook_repo` dependency. Jobs started any other
    # way (a rake task, a retry of a payload from before this existed) carry no
    # `webhook_id` and are left untracked.
    module WebhookTracking
      private

      def track_webhook(webhook_id)
        return yield if webhook_id.nil?

        webhook_repo.mark_running(webhook_id)
        result = yield
        webhook_repo.mark_succeeded(webhook_id)
        result
      rescue StandardError => error
        webhook_repo.mark_failed(webhook_id, error: "#{error.class}: #{error.message}")
        raise
      end
    end
  end
end
