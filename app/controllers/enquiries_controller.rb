class EnquiriesController < ApplicationController
  before_action :authenticate_account!, only: [:index, :update]

  def create
    permitted = params.require(:enquiry).permit(:property_id, :name, :email, :message, :website)
    @property = Property.find(permitted[:property_id])
    attrs = permitted.except(:property_id, :website)
    @enquiry = @property.enquiries.build(attrs)

    # Low-cost first line of abuse defence; operational IP-level throttling is
    # a separate requirement before public production release.
    if permitted[:website].present?
      redirect_to property_path(@property), notice: "Thank you for your message."
      return
    end

    if @enquiry.valid? && Enquiry.where(property_id: @property.id, email: @enquiry.email)
        .where("created_at >= ?", 1.hour.ago).count >= 3
      @enquiry.errors.add(:base, "Too many messages. Please try again later.")
    end

    if @enquiry.errors.empty? && @enquiry.save
      begin
        # Delivery is best-effort; the DB entry is the durable source of truth.
        # Configure SMTP and PROPERTY_FINDER_MAIL_FROM before production use.
        EnquiryMailer.with(enquiry_id: @enquiry.id).new_enquiry.deliver_now
      rescue StandardError => error
        Rails.logger.error("Enquiry notification failed (id=#{@enquiry.id}, error=#{error.class})")
      end
      redirect_to property_path(@property), notice: "Enquiry received. The agent can review it in their inbox."
    else
      @related_properties = Property.where(account_id: @property.account_id, status: "available")
        .where.not(id: @property.id).order(created_at: :desc).limit(3)
      render "properties/detail", status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def index
    @show_sidebar = true
    @enquiries = Enquiry.joins(:property)
      .where(properties: { account_id: current_account.id })
      .includes(:property).order(created_at: :desc).limit(100)
    @agent_messages = current_account.agent_messages.order(created_at: :desc).limit(100)
  end

  def update
    @enquiry = Enquiry.joins(:property)
      .where(properties: { account_id: current_account.id }).find(params[:id])
    new_status = params.require(:enquiry).permit(:status)[:status]
    unless Enquiry::STATUSES.include?(new_status)
      redirect_to enquiries_path, alert: "Invalid enquiry status."
      return
    end
    @enquiry.update!(status: new_status)
    redirect_to enquiries_path, notice: "Enquiry status updated."
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
