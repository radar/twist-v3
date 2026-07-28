# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :invites do
      primary_key :id
      column :email, String, null: false
      column :token, String, null: false
      column :accepted_at, DateTime

      foreign_key :invited_by_id, :users, on_delete: :cascade, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false

      index :token, unique: true
    end

    create_table :invite_books do
      foreign_key :invite_id, :invites, on_delete: :cascade, null: false
      foreign_key :book_id, :books, on_delete: :cascade, null: false

      index [:invite_id, :book_id], unique: true
    end
  end
end
