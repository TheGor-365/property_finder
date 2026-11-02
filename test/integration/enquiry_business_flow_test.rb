require "test_helper"

class EnquiryBusinessFlowTest < ActionDispatch::IntegrationTest
  setup do
    @agent = Account.create!(first_name: "Primary", last_name: "Agent",
      email: "enquiry-owner-#{SecureRandom.hex(6)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    @other = Account.create!(first_name: "Second", last_name: "Agent",
      email: "enquiry-other-#{SecureRandom.hex(6)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    @property = Property.create!(account: @agent, name: "Enquiry Test House",
      address: "42 Validation Road", price: 180_000, rooms: 2, bathrooms: 1,
      for_sale: true, status: "available")
    @attrs = { property_id: @property.id, name: "Visitor Name",
      email: "Visitor@Example.test", message: "I would like to arrange a viewing please." }
    ActionMailer::Base.deliveries.clear
  end

  test "guest enquiry persists and notifies the correct agent" do
    assert_difference "Enquiry.count", 1 do
      post enquiries_path, params: { enquiry: @attrs }
    end
    assert_redirected_to property_path(@property)
    assert_equal "Enquiry received. The agent can review it in their inbox.", flash[:notice]
    follow_redirect!
    assert_response :success
    assert_select "#flash-messages .alert-success", text: /Enquiry received/
    record = Enquiry.order(:id).last
    assert_equal @property.id, record.property_id
    assert_equal "visitor@example.test", record.email
    assert_equal "new", record.status
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [@agent.email], ActionMailer::Base.deliveries.last.to
  end

  test "invalid data remains visible to correct in-browser form" do
    assert_no_difference "Enquiry.count" do
      post enquiries_path, params: { enquiry: @attrs.merge(email: "invalid", message: "short") }
    end
    assert_response :unprocessable_entity
    assert_select "main#property-detail", count: 1
    assert_select "#contact-modal .alert-danger", minimum: 1
    assert_select 'form#email_agent[action=?]', enquiries_path, count: 1
  end

  test "closed listing rejects a new enquiry" do
    @property.update!(status: "sold")
    assert_no_difference "Enquiry.count" do
      post enquiries_path, params: { enquiry: @attrs }
    end
    assert_response :unprocessable_entity
  end

  test "agent inbox is private and other agents cannot update" do
    post enquiries_path, params: { enquiry: @attrs }
    enquiry = Enquiry.order(:id).last
    get enquiries_path
    assert_response :redirect
    post account_session_path, params: { account: { email: @other.email, password: "samplePassword2026!" } }
    get enquiries_path
    assert_response :success
    assert_select "#agent-enquiries #enquiry-#{enquiry.id}", count: 0
    patch enquiry_path(enquiry), params: { enquiry: { status: "closed" } }
    assert_response :not_found
    assert_equal "new", enquiry.reload.status
    delete destroy_account_session_path
    post account_session_path, params: { account: { email: @agent.email, password: "samplePassword2026!" } }
    get enquiries_path
    assert_response :success
    assert_select "#agent-enquiries #enquiry-#{enquiry.id}", count: 1
    patch enquiry_path(enquiry), params: { enquiry: { status: "contacted" } }
    assert_redirected_to enquiries_path
    assert_equal "contacted", enquiry.reload.status

    patch enquiry_path(enquiry), params: { enquiry: { status: "invalid" } }
    assert_redirected_to enquiries_path
    assert_equal "Invalid enquiry status.", flash[:alert]
    assert_equal "contacted", enquiry.reload.status
  end

  test "rate limit rejects a fourth enquiry within one hour" do
    3.times do
      post enquiries_path, params: { enquiry: @attrs }
      assert_redirected_to property_path(@property)
    end

    assert_no_difference "Enquiry.count" do
      post enquiries_path, params: { enquiry: @attrs }
    end
    assert_response :unprocessable_entity
    assert_select "#contact-modal .alert-danger", text: /Too many messages/
  end

  test "bot trap does not create records" do
    assert_no_difference "Enquiry.count" do
      post enquiries_path, params: { enquiry: @attrs.merge(website: "spam.example") }
    end
    assert_redirected_to property_path(@property)
  end
end
