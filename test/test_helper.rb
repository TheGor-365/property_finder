ENV["RAILS_ENV"] = "test"

require_relative "../config/environment"
require "rails/test_help"

# Rack::Attack uses a process-wide in-memory store in CI. Without resetting
# between tests, the random test order can exhaust a previous test's IP
# budget and cause unrelated later examples to receive HTTP 429.
# Keep counters intact within each individual test for throttle assertions.
class ActiveSupport::TestCase
  setup do
    Rack::Attack.cache.store.clear
  end
end
