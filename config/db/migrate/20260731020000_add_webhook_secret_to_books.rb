# frozen_string_literal: true

ROM::SQL.migration do
  # Nullable on purpose: a book without a secret keeps accepting unsigned
  # webhook deliveries, so existing books do not break when this ships. Setting
  # a secret is what turns signature verification on for that book.
  change do
    add_column :books, :webhook_secret, String
  end
end
