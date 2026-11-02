require "test_helper"

class PropertyCatalogTest < ActionDispatch::IntegrationTest
  setup do
    @owner = Account.create!(
      first_name: "Catalog", last_name: "Tester", email: "catalog-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!"
    )
    @sale = create_property("Oak Street Apartment", "Oak Street", 150_000, 3, true)
    @rent = create_property("River View Flat", "River Road", 2_000, 2, false)
    @closed = create_property("Closed Listing", "Oak Street", 60_000, 4, true, "sold")
  end

  test "public catalogue exposes available properties but not closed listings" do
    get properties_path
    assert_response :success
    assert_select "main#property-catalog"
    assert_select "form[action=?][method=get]", properties_path
    assert_select "a[href=?]", property_path(@sale), minimum: 1
    assert_select "a[href=?]", property_path(@rent), minimum: 1
    assert_select "a[href=?]", property_path(@closed), 0
    assert_select 'meta[name="viewport"][content="width=device-width, initial-scale=1"]'
  end

  test "search, listing type, prices and minimum bedrooms" do
    get properties_path, params: { q: "Oak Street", transaction: "sale", min_price: "100000", max_price: "200000", rooms: "3" }
    assert_response :success
    assert_select "a[href=?]", property_path(@sale), minimum: 1
    assert_select "a[href=?]", property_path(@rent), 0
    assert_select "a[href=?]", property_path(@closed), 0
    get properties_path, params: { transaction: "rent", max_price: "3000" }
    assert_response :success
    assert_select "a[href=?]", property_path(@rent), minimum: 1
    assert_select "a[href=?]", property_path(@sale), 0
  end

  test "pagination preserves query parameters and sorts by price" do
    # Unique per run: preview/demo records already in the test DB must not affect counts.
    marker = "PF-Pagination-#{SecureRandom.hex(12)}"
    11.times { |i| create_property("#{marker} Apartment #{i}", "Market Lane", 100_000 + i, 2, true) }
    get properties_path, params: { q: marker, transaction: "sale", sort: "price_desc" }
    assert_response :success
    assert_select 'nav[aria-label="Property results pagination"] a[rel="next"]', 1
    assert_select '.pf-catalog-results .pf-property-card', count: 9
    assert_match(/transaction=sale/, response.body)
    assert_match(/q=PF-Pagination-/, response.body)
    get properties_path, params: { q: marker, transaction: "sale", sort: "price_asc", page: "2" }
    assert_response :success
    assert_select '.pf-catalog-results .pf-property-card', count: 2
  end

  test "bad query inputs never raise and empty results have a usable reset" do
    get properties_path, params: { sort: { invalid: "param" }, page: "-10", rooms: "abc", q: "unfindable address" }
    assert_response :success
    assert_select ".pf-empty-state"
    assert_select "a[href=?]", properties_path, minimum: 1
    get properties_path, params: { min_price: "900000", max_price: "100" }
    assert_response :success
    assert_select ".pf-empty-state"
  end

  private

  def create_property(name, address, price, rooms, for_sale, status = "available")
    Property.create!(
      account: @owner, name: name, address: address, price: price,
      rooms: rooms, bathrooms: 1, parking_spaces: 0,
      for_sale: for_sale, status: status
    )
  end
end
