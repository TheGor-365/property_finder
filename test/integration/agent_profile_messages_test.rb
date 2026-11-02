require "test_helper"

class AgentProfileMessagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @agent = Account.create!(first_name: "Profile", last_name: "Agent",
      email: "profile-message-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    @other = Account.create!(first_name: "Other", last_name: "Agent",
      email: "other-message-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    @data = { name: "Visitor Name", email: "Visitor@Example.test",
      message: "I would like to ask about your listed homes." }
    ActionMailer::Base.deliveries.clear
    Rack::Attack.cache.store.clear
  end

  teardown do
    Rack::Attack.cache.store.clear
  end

  test "public agent profile form persists and notifies the correct account" do
    get profile_path(@agent)
    assert_response :success
    assert_select "form[action=?]", profile_email_agent_path(@agent), count: 1

    assert_difference "AgentMessage.count", 1 do
      post profile_email_agent_path(@agent), params: { agent_message: @data }
    end
    assert_redirected_to profile_path(@agent)
    record = AgentMessage.order(:id).last
    assert_equal @agent.id, record.account_id
    assert_equal "visitor@example.test", record.email
    assert_equal "new", record.status
    assert_equal [@agent.email], ActionMailer::Base.deliveries.last.to
    follow_redirect!
    assert_response :success
    assert_select "#flash-messages .alert-success", text: /Message received/
  end

  test "invalid form preserves visitor inputs and displays errors" do
    assert_no_difference "AgentMessage.count" do
      post profile_email_agent_path(@agent),
        params: { agent_message: @data.merge(email: "invalid", message: "short") }
    end
    assert_response :unprocessable_entity
    assert_select "#contact-modal .alert-danger", minimum: 1
    assert_select "input[name='agent_message[name]'][value='Visitor Name']", count: 1
    assert_select "input[name='agent_message[email]'][value='invalid']", count: 1
    assert_select "textarea[name='agent_message[message]']", text: "short"
  end

  test "honeypot and rate limit do not create additional messages" do
    assert_no_difference "AgentMessage.count" do
      post profile_email_agent_path(@agent),
        params: { agent_message: @data.merge(website: "bot.example") }
    end
    assert_redirected_to profile_path(@agent)

    3.times do
      post profile_email_agent_path(@agent), params: { agent_message: @data }
      assert_redirected_to profile_path(@agent)
    end

    assert_no_difference "AgentMessage.count" do
      post profile_email_agent_path(@agent), params: { agent_message: @data }
    end
    assert_response :unprocessable_entity
    assert_select "#contact-modal .alert-danger", text: /Too many messages/
  end

  test "profile inbox and status changes are private to the agent" do
    post profile_email_agent_path(@agent), params: { agent_message: @data }
    record = AgentMessage.order(:id).last

    get enquiries_path
    assert_response :redirect

    sign_in @other
    get enquiries_path
    assert_response :success
    assert_select "#agent-message-#{record.id}", count: 0

    patch agent_message_path(record), params: { agent_message: { status: "closed" } }
    assert_response :not_found
    assert_equal "new", record.reload.status

    sign_out @other
    sign_in @agent
    get enquiries_path
    assert_response :success
    assert_select "#agent-message-#{record.id}", count: 1

    patch agent_message_path(record), params: { agent_message: { status: "contacted" } }
    assert_redirected_to enquiries_path
    assert_equal "contacted", record.reload.status

    patch agent_message_path(record), params: { agent_message: { status: "unknown" } }
    assert_redirected_to enquiries_path
    assert_equal "contacted", record.reload.status
  end

  test "unknown agent profile does not create a record" do
    assert_no_difference "AgentMessage.count" do
      post profile_email_agent_path(999999), params: { agent_message: @data }
    end
    assert_response :not_found
  end

  test "legacy property contact is persisted as an enquiry before returning success" do
    listing = Property.create!(account: @agent, name: "Legacy contact test",
      address: "Test Street", price: 20000)
    assert_difference "Enquiry.count", 1 do
      post email_agent_path, params: { property_id: listing.id, first_name: "Test",
        last_name: "Visitor", email: "person@example.test",
        message: "Please send me more information." }, as: :json
    end
    assert_response :no_content
    record = Enquiry.order(:id).last
    assert_equal listing.id, record.property_id
    assert_equal @agent.email, ActionMailer::Base.deliveries.last.to
  end
end
