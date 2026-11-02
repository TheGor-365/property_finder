require "test_helper"

class PublicContactSecurityTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.cache.store.clear
    @owner = Account.create!(
      email: "public-security-#{SecureRandom.hex(6)}@example.test",
      password: "samplePassword2026!",
      password_confirmation: "samplePassword2026!"
    )
    @available = Property.create!(
      account: @owner, name: "Visible property #{SecureRandom.hex(4)}",
      address: "Published test address", price: 120_000, status: "available"
    )
    @sold = Property.create!(
      account: @owner, name: "Sold property #{SecureRandom.hex(4)}",
      address: "Closed test address", price: 110_000,
      for_sale: true, status: "sold"
    )
  end

  teardown do
    Rack::Attack.cache.store.clear
  end

  test "anonymous JSON catalogue excludes closed listings as HTML catalogue does" do
    get properties_path(format: :json)
    assert_response :success
    ids = response.parsed_body.map { |row| row.fetch("id") }
    assert_includes ids, @available.id
    refute_includes ids, @sold.id

    get properties_path
    assert_response :success
    assert_select "a[href=?]", property_path(@available), minimum: 1
    assert_select "a[href=?]", property_path(@sold), count: 0
  end

  test "sixth enquiry request from same IP is throttled before any database write" do
    5.times do
      post enquiries_path,
        params: { enquiry: { property_id: 999_999_999 } }
      assert_response :not_found
    end

    assert_no_difference "Enquiry.count" do
      post enquiries_path,
        params: { enquiry: { property_id: @available.id,
          name: "Visitor", email: "visitor@example.test",
          message: "I would like to arrange a viewing please." } }
    end
    assert_response :too_many_requests

    get root_path
    assert_response :success
  end

  test "legacy contact and modern enquiry share the same anti-abuse IP budget" do
    3.times do
      post email_agent_path, params: { property_id: 999_999_999 }, as: :json
      assert_response :not_found
    end

    2.times do
      post enquiries_path, params: { enquiry: { property_id: 999_999_999 } }
      assert_response :not_found
    end

    post enquiries_path, params: { enquiry: { property_id: 999_999_999 } }
    assert_response :too_many_requests
  end
end
