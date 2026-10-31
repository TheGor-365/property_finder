class ContactMailer < ApplicationMailer
  def email_agent agent, first_name, last_name, email, message

    @agent = agent

    @first_name = first_name
    @last_name = last_name
    @email = email
    @message = message

    mail to: @agent.email, subject: "New property enquiry"
  end
end
