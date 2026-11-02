# Database-backed health endpoint for Railway. No secrets or stack traces in HTTP.
class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    head :ok
  rescue StandardError => error
    Rails.logger.warn("Property Finder health check failed: #{error.class}")
    head :service_unavailable
  end
end
