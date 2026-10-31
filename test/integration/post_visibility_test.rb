require "test_helper"

class PostVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @published = Post.create!(
      title: "Public test article",
      body: "Visible public content",
      active: true
    )

    @draft = Post.create!(
      title: "Private test draft",
      body: "Confidential draft content",
      active: false
    )
  end

  test "public blog lists only published posts" do
    get blog_path

    assert_response :success
    assert_includes response.body, @published.title
    refute_includes response.body, @draft.title
  end

  test "guest can view published post" do
    get post_path(@published)

    assert_response :success
    assert_includes response.body, @published.body
  end

  test "guest cannot view draft by direct URL" do
    get post_path(@draft)

    assert_response :not_found
  end

  test "ordinary account cannot view draft" do
    sign_in create_account("member", false)

    get post_path(@draft)

    assert_response :not_found
  end

  test "administrator can preview draft" do
    sign_in create_account("admin", true)

    get post_path(@draft)

    assert_response :success
    assert_includes response.body, @draft.body
  end

  private

  def create_account(role, admin)
    Account.create!(
      email: "#{role}-#{SecureRandom.hex(6)}@example.test",
      password: "test_password_123",
      password_confirmation: "test_password_123",
      admin: admin
    )
  end
end
