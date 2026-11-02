# Temporary local/test store. Production requires shared storage.
# Both listing enquiries and direct agent messages share the same IP budget.
if Rails.env.development? || Rails.env.test?
  Rack::Attack.cache.store =
    ActiveSupport::Cache::MemoryStore.new(size: 16.megabytes)
end

Rack::Attack.throttle("agent_contact/minute", limit: 5, period: 60) do |req|
  req.ip if req.post? && (
    req.path == "/agent/message" ||
    req.path == "/enquiries" ||
    req.path.match?(%r{\A/profile/\d+/message\z})
  )
end

Rack::Attack.throttle("agent_contact/hour", limit: 20, period: 3600) do |req|
  req.ip if req.post? && (
    req.path == "/agent/message" ||
    req.path == "/enquiries" ||
    req.path.match?(%r{\A/profile/\d+/message\z})
  )
end
