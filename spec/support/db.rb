# frozen_string_literal: true

# Tag every example as `:db`, unless it opts out with `db: false`.
#
# Without this, only feature specs were cleaned between examples, so anything
# written by a request/processor spec leaked into every later example and
# produced order-dependent failures.
#
# See support/db/cleaning.rb for how the database is cleaned around these `:db` examples.
RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    metadata[:db] = true unless metadata.key?(:db)
  end
end
