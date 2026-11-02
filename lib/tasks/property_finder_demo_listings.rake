namespace :pf do
  namespace :demo do
    desc "Fill blank descriptions of the 12 verified DEMO listings (isolated test DB only)"
    task listing_copy: :environment do
      database = ActiveRecord::Base.connection_db_config.database.to_s
      abort "STOP: isolated test DB required" unless Rails.env.test? &&
        database.downcase.include?("test")

      agent = Account.find_by(email: "pf-catalog-showcase@example.invalid")
      abort "STOP: unexpected demo account" unless agent &&
        agent.first_name == "Demo" && agent.last_name == "Agent"

      listings = Property.where(account_id: agent.id).order(:id).to_a
      abort "STOP: expected 12 strictly labelled demo listings" unless listings.size == 12 &&
        listings.all? { |property| property.name.to_s.start_with?("DEMO -") }

      count = 0
      Property.transaction do
        listings.each do |property|
          next if property.details.present?

          label = property.name.to_s.delete_prefix("DEMO -").strip
          kind = property.for_sale? ? "for-sale" : "rental"
          rooms = property.rooms.nil? ? "not specified" : property.rooms.to_s
          bathrooms = property.bathrooms.nil? ? "not specified" : property.bathrooms.to_s
          parking = property.parking_spaces.nil? ? "not specified" : property.parking_spaces.to_s
          price = property.price.to_i.positive? ? "$#{property.price.to_i}" : "on request"

          description = <<~COPY.strip
            #{label} is a fictional #{kind} example created for the Property Finder software showcase. It demonstrates how a visitor can compare property information, navigate to an agent profile and submit a genuine test enquiry to the application database. No real home is offered through this listing.

            The sample record describes #{rooms} bedrooms, #{bathrooms} bathrooms and #{parking} parking spaces, with a demonstration asking price of #{price}#{property.for_sale? ? "" : " per month"}. The address and the illustration are placeholders, not verified property details or photographs. These figures should not be used for a rental or purchase decision.

            Open the contact form to explore validation and confirmation, then sign in as the demonstration listing agent to review and update the resulting enquiry status. The workflow is real software; the displayed inventory is intentionally fictitious.
          COPY

          property.update!(details: description)
          count += 1
        end
      end

      puts "PF_DEMO_LISTINGS_TOTAL=#{listings.size}"
      puts "PF_DEMO_LISTING_DESCRIPTIONS_CREATED=#{count}"
      puts "PF_DEMO_LISTING_DESCRIPTIONS_PRESERVED=#{listings.size - count}"
      puts "PF_DEMO_LISTING_COPY_SCOPE=test"
    end
  end
end
