require "test_helper"

class PropertyDetailPresentationTest < ActionDispatch::IntegrationTest
  def detail_diagnostic!
    puts "DETAIL_RESPONSE_STATUS=#{response.status}"
    request_exception = request.env["action_dispatch.exception"]
    if request_exception
      puts "DETAIL_EXCEPTION=#{request_exception.class}: #{request_exception.message.to_s.lines.first.to_s.strip[0, 350]}"
      puts "DETAIL_BACKTRACE=#{Array(request_exception.backtrace).first(8).join(' | ')[0, 1400]}"
    end
    html = response.body.to_s
    match = html.match(/<h1[^>]*>(.*?)<\/h1>/im)
    puts "DETAIL_ERROR_HEADING=#{match[1].gsub(/<[^>]*>/, '').strip[0, 350]}" if match
    puts "DETAIL_RESPONSE_BYTES=#{html.bytesize}"
  end

  setup do
    @agent = Account.create!(first_name: "Avery", last_name: "Agent",
      email: "detail-agent-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    @property = Property.create!(account: @agent, name: "Garden Apartment", address: "17 Garden Street",
      price: 185_000, rooms: 3, bathrooms: 2, parking_spaces: 1,
      for_sale: true, status: "available", details: "A test listing with an open plan living area.")
  end

  test "guest can view a complete detail page with agent and enquiry action" do
    get property_path(@property)
    detail_diagnostic! if response.status >= 500
    assert_response :success
    assert_select "main#property-detail", count: 1
    assert_select "h1", text: /Garden Apartment/
    assert_select 'a[href=?]', properties_path, minimum: 1
    assert_select 'a[href=?]', profile_path(@agent), minimum: 1
    assert_select '[data-toggle="modal"][data-target="#contact-modal"]', minimum: 1
    assert_select "#contact-modal", count: 1
    assert_select "#contact-modal #email_agent", count: 1
    assert_select "#contact-modal #message-first-name", count: 1
    assert_select "#contact-modal #message-email", count: 1
    assert_select "#contact-modal textarea#message-text", count: 1
    assert_select "img.pf-detail-cover-img[alt]", count: 1
    assert_no_match(/AIza[0-9A-Za-z_-]{20,}/, response.body)
    assert_no_match(/Feather is a collection of SVG files/, response.body)
  end

  test "closed listing displays status and does not offer enquiry" do
    @property.update!(status: "sold")
    get property_path(@property)
    assert_response :success
    assert_select ".pf-detail-status-closed", text: /Sold/
    assert_select '[data-target="#contact-modal"]', count: 0
    assert_select "#contact-modal", count: 0
  end

  test "rental has accurate monthly price and availability without placeholder mortgage claims" do
    @property.update!(for_sale: false, price: 2150, available_date: Date.new(2027, 1, 15))
    get property_path(@property)
    detail_diagnostic! if response.status >= 500
    assert_response :success
    assert_select ".pf-detail-status", text: /For rent/
    assert_select ".pf-detail-price", text: /2,150.*month/m
    assert_select ".pf-detail-availability", text: /January.*2027/
    assert_no_match(/Est. Mountly Repaments/, response.body)
  end
end
