namespace :pf do
  namespace :demo do
    desc "Fill only missing public introduction of the verified DEMO agent in the isolated test DB"
    task agent_profile_copy: :environment do
      database = ActiveRecord::Base.connection_db_config.database.to_s
      abort "STOP: isolated test database required" unless Rails.env.test? &&
        database.downcase.include?("test")

      agent = Account.find_by(email: "pf-catalog-showcase@example.invalid")
      abort "STOP: wrong demo agent" unless agent &&
        agent.first_name == "Demo" && agent.last_name == "Agent"

      listings = agent.properties.pluck(:name)
      abort "STOP: unexpected DEMO ownership" unless listings.size == 12 &&
        listings.all? { |name| name.to_s.start_with?("DEMO -") }

      if agent.details.present?
        puts "PF_DEMO_AGENT_PROFILE_PRESERVED=YES"
      else
        agent.update!(details: <<~TEXT.strip)
          Welcome to the Property Finder demonstration agent profile. This is a fictional account used to showcase a real Ruby on Rails workflow, not a licensed estate agency or a person offering real properties.

          Explore twelve example homes, filter the catalogue, view listing information and contact this agent using a working enquiry form. Your test message is stored in a private inbox where the agent can mark it as New, Contacted or Closed.

          All properties, addresses, figures and illustrations associated with this DEMO account are sample material. There are no real viewings, property transfers, payments or brokerage services.
        TEXT
        puts "PF_DEMO_AGENT_PROFILE_CREATED=YES"
      end
      puts "PF_DEMO_AGENT_PROFILE_SCOPE=test"
    end
  end
end
