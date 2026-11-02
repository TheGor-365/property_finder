class AgentMessagesController < ApplicationController
  before_action :authenticate_account!, only: :update

  def create
    @account = Account.find(params[:profile_id])
    permitted = params.require(:agent_message).permit(:name, :email, :message, :website)
    @agent_message = @account.agent_messages.build(permitted.except(:website))

    if permitted[:website].present?
      redirect_to profile_path(@account), notice: "Thank you for your message."
      return
    end

    if @agent_message.valid? && AgentMessage.where(
        account_id: @account.id, email: @agent_message.email
      ).where("created_at >= ?", 1.hour.ago).count >= 3
      @agent_message.errors.add(:base, "Too many messages. Please try again later.")
    end

    if @agent_message.errors.empty? && @agent_message.save
      begin
        AgentMessageMailer.with(agent_message_id: @agent_message.id).new_message.deliver_now
      rescue StandardError => error
        Rails.logger.error("Agent message email failed (id=#{@agent_message.id}, error=#{error.class})")
      end
      redirect_to profile_path(@account),
        notice: "Message received. The agent can review it in their inbox."
    else
      load_profile_data
      render "dashboard/profile", status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def update
    message = current_account.agent_messages.find(params[:id])
    status = params.require(:agent_message).permit(:status)[:status]

    unless AgentMessage::STATUSES.include?(status)
      redirect_to enquiries_path, alert: "Invalid message status."
      return
    end

    message.update!(status: status)
    redirect_to enquiries_path, notice: "Agent message status updated."
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def load_profile_data
    listings = @account.properties
    @properties = listings.where(status: "available").order(created_at: :desc)
    @properties_sold = listings.sold.count
    @properties_for_sale = listings.for_sale.count
    @properties_leased = listings.leased.count
    @properties_for_rent = listings.for_rent.count
    @show_sidebar = true if account_signed_in?
  end
end
