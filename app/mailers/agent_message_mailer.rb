class AgentMessageMailer < ApplicationMailer
  def new_message
    @message = AgentMessage.includes(:account).find(params.fetch(:agent_message_id))
    @agent = @message.account
    mail(to: @agent.email,
      from: ENV.fetch("PROPERTY_FINDER_MAIL_FROM", "Property Finder <no-reply@example.test>"),
      subject: "Property Finder: new message from agent profile")
  end
end
