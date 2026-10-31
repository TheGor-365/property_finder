require "test_helper"

class AgentContactTest < ActionDispatch::IntegrationTest
  setup do
    @agent = create_account("agent")
    @other = create_account("other")

    @property = Property.create!(
      account: @agent,
      name: "Contact test property",
      address: "Test street",
      price: 100000
    )

    ActionMailer::Base.deliveries.clear
  end

  test "valid enquiry reaches property owner" do
    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      submit_contact
    end

    assert_response :no_content
    assert_equal [@agent.email], ActionMailer::Base.deliveries.last.to
  end

  test "forged agent id cannot redirect enquiry" do
    submit_contact(agent_id: @other.id)

    assert_response :no_content
    assert_equal [@agent.email], ActionMailer::Base.deliveries.last.to
  end

  test "unknown property does not trigger delivery" do
    submit_contact(property_id: 999999999)

    assert_response :not_found
    assert_empty ActionMailer::Base.deliveries
  end

  test "blank message is rejected" do
    submit_contact(message: "   ")

    assert_response :unprocessable_entity
    assert_empty ActionMailer::Base.deliveries
  end

  test "invalid email is rejected" do
    submit_contact(email: "invalid-email")

    assert_response :unprocessable_entity
    assert_empty ActionMailer::Base.deliveries
  end

  private

  def submit_contact(overrides = {})
    payload = {
      property_id: @property.id,
      first_name: "Test",
      last_name: "Visitor",
      email: "visitor@example.test",
      message: "I would like more information."
    }.merge(overrides)

    post email_agent_path, params: payload, as: :json
  end

  def create_account(role)
    password = "test_password_123"

    Account.create!(
      email: "#{role}-#{SecureRandom.hex(6)}@example.test",
      password: password,
      password_confirmation: password
    )
  end
end
