class EnquiryMailer < ApplicationMailer
  def new_enquiry
    @enquiry = Enquiry.includes(property: :account).find(params.fetch(:enquiry_id))
    @property = @enquiry.property
    @agent = @property.account
    mail(to: @agent.email,
      from: ENV.fetch("PROPERTY_FINDER_MAIL_FROM", "Property Finder <no-reply@example.test>"),
      subject: "Property Finder: new enquiry about #{@property.name}")
  end
end
