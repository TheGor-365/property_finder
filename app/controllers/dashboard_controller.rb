class DashboardController < ApplicationController
  before_action :authenticate_account!, only: :index
  before_action :set_sidebar

  def index
    properties = current_account.properties

    @total_properties = properties.count
    @for_sale_count = properties.for_sale.count
    @for_rent_count = properties.for_rent.count
    @completed_count = properties.sold.count + properties.leased.count
    @recent_properties = properties.order(created_at: :desc).limit(10)
    @new_enquiries_count = Enquiry.joins(:property)
      .where(properties: { account_id: current_account.id }, status: "new").count +
      current_account.agent_messages.where(status: "new").count
  end

  def profile
    @account = Account.find(params[:id])
    @properties = Property.where(account_id: @account.id, status: 'available').order(created_at: :desc)

    @properties_sold      = Property.where(account_id: @account.id).sold.count
    @properties_for_sale  = Property.where(account_id: @account.id).for_sale.count
    @properties_leased    = Property.where(account_id: @account.id).leased.count
    @properties_for_rent  = Property.where(account_id: @account.id).for_rent.count
  end

  private

  def set_sidebar
    @show_sidebar = true if account_signed_in?
  end
end
