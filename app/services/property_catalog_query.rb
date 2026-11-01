# Server-side, shareable public catalogue filters. No new gems required.
class PropertyCatalogQuery
  PER_PAGE = 9
  MAX_PRICE = 1_000_000_000
  SORTS = {
    "newest" => { created_at: :desc, id: :desc },
    "oldest" => { created_at: :asc, id: :asc },
    "price_asc" => { price: :asc, id: :asc },
    "price_desc" => { price: :desc, id: :desc }
  }.freeze

  attr_reader :q, :transaction, :min_price, :max_price, :rooms, :sort, :page

  def initialize(params)
    @q = input(params, :q).strip[0, 120]
    @transaction = %w[sale rent].include?(input(params, :transaction)) ? input(params, :transaction) : ""
    @min_price = money(input(params, :min_price))
    @max_price = money(input(params, :max_price))
    @rooms = integer(input(params, :rooms), 1, 20)
    raw_sort = input(params, :sort)
    @sort = SORTS.key?(raw_sort) ? raw_sort : "newest"
    @requested_page = integer(input(params, :page), 1, 100_000) || 1
  end

  def query_params
    { q: q, transaction: transaction, min_price: min_price,
      max_price: max_price, rooms: rooms, sort: sort }.compact
  end

  def filters_applied?
    q.present? || transaction.present? || min_price.present? || max_price.present? || rooms.present?
  end

  def total_count
    @total_count ||= filtered_scope.count
  end

  def total_pages
    [(total_count.to_f / PER_PAGE).ceil, 1].max
  end

  def page
    @page ||= [@requested_page, total_pages].min
  end

  def previous_page
    page > 1 ? page - 1 : nil
  end

  def next_page
    page < total_pages ? page + 1 : nil
  end

  def records
    filtered_scope.order(SORTS.fetch(sort)).limit(PER_PAGE).offset((page - 1) * PER_PAGE)
  end

  private

  def filtered_scope
    @filtered_scope ||= begin
      scope = Property.where(status: "available")
      if q.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
        scope = scope.where("properties.name ILIKE :pattern OR properties.address ILIKE :pattern", pattern: pattern)
      end
      scope = scope.where(for_sale: transaction == "sale") if transaction.present?
      scope = scope.where("properties.price >= ?", min_price) if min_price
      scope = scope.where("properties.price <= ?", max_price) if max_price
      scope = scope.where("properties.rooms >= ?", rooms) if rooms
      scope = scope.none if min_price && max_price && min_price > max_price
      scope
    end
  end

  def input(params, key)
    value = params[key]
    value.is_a?(String) ? value : ""
  end

  def money(value)
    integer(value, 0, MAX_PRICE)
  end

  def integer(value, lower, upper)
    return nil unless value.match?(/\A\d{1,12}\z/)
    number = value.to_i
    number if number.between?(lower, upper)
  end
end
