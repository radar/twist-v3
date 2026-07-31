# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :webhooks do
      primary_key :id

      foreign_key :book_id, :books, on_delete: :cascade, null: false

      column :event, String
      column :ref, String
      column :delivery_id, String

      column :received_at, DateTime, null: false

      # One background job per received webhook: pending -> enqueued -> running
      # -> succeeded / failed.
      column :job_status, String, null: false, default: "pending"
      column :job_id, String
      column :job_started_at, DateTime
      column :job_finished_at, DateTime
      column :job_error, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index [:book_id, :received_at]
      index :delivery_id
    end
  end
end
