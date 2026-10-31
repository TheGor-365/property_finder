require "test_helper"

class AgentRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store.clear
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    Rack::Attack.cache.store.clear
  end

  test "sixth contact request is blocked" do
    5.times do
      post email_agent_path,
        params: { property_id: 999999999 },
        as: :json

      assert_response :not_found
    end

    post email_agent_path,
      params: { property_id: 999999999 },
      as: :json

    assert_response :too_many_requests
    assert_empty ActionMailer::Base.deliveries
  end

  test "contact rate limit does not block public pages" do
    6.times do
      post email_agent_path,
        params: { property_id: 999999999 },
        as: :json
    end

    get blog_path
    assert_response :success
  end
  test "twenty-first contact request exceeds hourly limit" do
    minute_rule = Rack::Attack.throttles.delete("agent_contact/minute")
    assert minute_rule, "Minute throttle must exist"

    begin
      20.times do
        post email_agent_path,
          params: { property_id: 999999999 },
          as: :json

        assert_response :not_found
      end

      post email_agent_path,
        params: { property_id: 999999999 },
        as: :json

      assert_response :too_many_requests
      assert_empty ActionMailer::Base.deliveries
    ensure
      Rack::Attack.throttles["agent_contact/minute"] = minute_rule if minute_rule
    end
  end

end
