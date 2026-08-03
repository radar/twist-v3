# frozen_string_literal: true

require "sidekiq/testing"

# Jobs go to an in-process array rather than Redis, so actions can enqueue
# freely and specs can assert on what was queued.
Sidekiq::Testing.fake!

RSpec.configure do |config|
  config.before { Sidekiq::Worker.clear_all }
end
