require "test_helper"

class EditorialPresentationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "published journal uses article cards and complete article page" do
    post = Post.create!(title: "A helpful buying guide", summary: "Comparing homes with clarity",
      body: "Record your priorities and ask for verifiable details.", active: true)

    get blog_path
    assert_response :success
    assert_select "#blog-banner"
    assert_select "a[href=?]", post_path(post), minimum: 1
    assert_select "article.pf-article-card", minimum: 1

    get post_path(post)
    assert_response :success
    assert_select "main.pf-article-page"
    assert_select ".pf-article-body", text: /Record your priorities/
    assert_select "a[href=?]", blog_path, minimum: 1
  end

  test "agent dashboard includes meaningful links and no old top margin" do
    agent = Account.create!(email: "editorial-agent-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    sign_in agent

    get dashboard_path
    assert_response :success
    assert_select "body.show_sidebar"
    assert_select "main.pf-workspace-main"
    assert_select "main.mt-5", count: 0
    assert_select "a[href=?]", enquiries_path, minimum: 1
    assert_select "a[href=?]", new_property_path, minimum: 1
  end

  test "new listing editor offers a usable structured form" do
    agent = Account.create!(email: "editor-owner-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    sign_in agent
    get new_property_path
    assert_response :success
    assert_select ".pf-editor-shell"
    assert_select "form input[name='property[name]']", count: 1
    assert_select "form select[name='property[for_sale]']", count: 1
    assert_select "form textarea[name='property[details]']", count: 1
  end
end
