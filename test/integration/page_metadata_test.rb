require "test_helper"

class PageMetadataTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @agent = Account.create!(
      email: "metadata-agent-#{SecureRandom.hex(6)}@example.test",
      password: "samplePassword2026!",
      password_confirmation: "samplePassword2026!"
    )
    @property = Property.create!(
      account: @agent, name: "Metadata & Demo Cottage",
      address: "Demonstration location", price: 180_000
    )
    @post = Post.create!(
      title: "Practical property viewing guide",
      body: "Useful test article content", active: true
    )
  end

  test "public pages have meaningful titles and descriptions" do
    get root_path
    assert_response :success
    assert_select "title", text: /portfolio demo/i
    assert_select 'meta[name="description"][content*="fictional home listings"]', count: 1
    assert_select 'meta[name="robots"]', count: 0

    get blog_path
    assert_select "title", text: /Journal.*Property Finder/
    assert_select 'meta[name="description"][content*="educational articles"]', count: 1

    get property_path(@property)
    assert_select "title", text: /Metadata & Demo Cottage/
    assert_select 'meta[name="description"][content*="not verified real estate offers"]', count: 1

    get post_path(@post)
    assert_select "title", text: /Practical property viewing guide/
  end

  test "private workspace and authentication pages are not indexable" do
    get new_account_session_path
    assert_response :success
    assert_select 'meta[name="robots"][content="noindex,nofollow"]'

    sign_in @agent
    get dashboard_path
    assert_response :success
    assert_select 'meta[name="robots"][content="noindex,nofollow"]'

    get enquiries_path
    assert_response :success
    assert_select 'meta[name="robots"][content="noindex,nofollow"]'
  end

  test "escaped metadata does not render markup from user-defined listing names" do
    @property.update!(name: "Demo <script>alert(1)</script> & House")
    get property_path(@property)
    assert_response :success
    assert_select "head script:not([src])", count: 0
    assert_match(/&lt;script&gt;/, response.body)
  end
end
