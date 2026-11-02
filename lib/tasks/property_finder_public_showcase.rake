require "securerandom"

namespace :pf do
  namespace :demo do
    desc "Create only clearly fictional portfolio examples (explicitly authorized production showcase)"
    task public_showcase: :environment do
      abort "STOP: public showcase opt-in missing" unless
        Rails.env.production? && ENV["PF_PUBLIC_SHOWCASE"] == "enabled"

      # Running in an existing Railway production database must not mutate
      # pre-existing real or independently authored listings.
      email = "pf-public-showcase@example.invalid"
      agent = Account.find_by(email: email)
      if agent
        abort "STOP: wrong showcase identity" unless
          agent.first_name == "Demo" && agent.last_name == "Agent" &&
          agent.company == "Property Finder Showcase"
      else
        agent = Account.create!(
          email: email, password: SecureRandom.urlsafe_base64(48),
          first_name: "Demo", last_name: "Agent",
          company: "Property Finder Showcase",
          details: "Fictional portfolio demonstration only. Illustrations, locations and prices are examples; no real property or brokerage services are offered."
        )
      end

      # A temporary owner-controlled viewing credential may be passed only via
      # the Railway service environment, never as seed data or in Git.
      # Replacing the variable with a fresh unknown random value later revokes
      # old temporary access without deleting demo data or enquiries.
      temporary_password = ENV["PF_PUBLIC_DEMO_AGENT_PASSWORD"].to_s
      if temporary_password.present?
        abort "STOP: unsafe demo password length" if temporary_password.length < 32
        abort "STOP: unexpected demo identity" unless agent.email ==
          "pf-public-showcase@example.invalid" &&
          agent.first_name == "Demo" && agent.last_name == "Agent"
        unless agent.valid_password?(temporary_password)
          agent.update!(
            password: temporary_password,
            password_confirmation: temporary_password
          )
        end
        puts "PUBLIC_SHOWCASE_AGENT_ACCESS_CONFIGURED=YES"
      end

      examples = [
        ["DEMO - City View Loft", "61 Sample Avenue, Example City", 285000, true, 2, 1, 1],
        ["DEMO - Modern Studio", "8 Model Street, Testborough", 149000, true, 1, 1, 0],
        ["DEMO - Garden Family Home", "9 Example Road, Testborough", 575000, true, 4, 3, 2],
        ["DEMO - Lakeside Retreat", "30 Fictional Drive, Sample City", 650000, true, 3, 2, 2],
        ["DEMO - Sunny Corner Flat", "4 Demo Square, Testborough", 219000, true, 2, 1, 1],
        ["DEMO - Compact Starter Home", "11 Model Street, Testborough", 198000, true, 2, 1, 1],
        ["DEMO - Urban Duplex", "24 Example Road, Sample City", 425000, true, 3, 2, 1],
        ["DEMO - Family Courtyard House", "12 Fictional Lane, Testborough", 510000, true, 4, 2, 2],
        ["DEMO - Terrace Rental", "17 Example Lane, Testborough", 2350, false, 3, 2, 1],
        ["DEMO - Family Rental House", "22 Fictional Drive, Testborough", 2900, false, 4, 2, 2],
        ["DEMO - Central Rental Studio", "19 Demo Square, Sample City", 1100, false, 1, 1, 0],
        ["DEMO - Riverside Rental", "7 Example Quay, Sample City", 1850, false, 2, 1, 1]
      ]

      known = examples.map(&:first)
      current = Property.where(account_id: agent.id).pluck(:name)
      abort "STOP: unexpected owner listings" unless (current - known).empty?
      created = 0
      Property.transaction do
        examples.each do |name, address, price, for_sale, beds, baths, parking|
          next if Property.exists?(account_id: agent.id, name: name)
          summary = "#{name.delete_prefix('DEMO - ')} is fictional sample inventory for an educational Rails portfolio. It is not an actual property offer. The address, price and imagery are illustrative; no viewings, payments, sales or rentals take place. The functioning contact form demonstrates validated database persistence, not a real-estate brokerage service."
          Property.create!(
            account: agent, name: name, address: address, price: price,
            for_sale: for_sale, status: "available", rooms: beds,
            bathrooms: baths, parking_spaces: parking, details: summary
          )
          created += 1
        end
      end
      Rake::Task["pf:demo:articles"].invoke
      puts "PUBLIC_SHOWCASE_PROPERTY_TOTAL=#{agent.properties.count}"
      puts "PUBLIC_SHOWCASE_PROPERTY_CREATED=#{created}"
      puts "PUBLIC_SHOWCASE_ARTICLES_TOTAL=#{Post.where('url LIKE ?', 'pf-demo-%').count}"
      puts "PUBLIC_SHOWCASE_SCOPE=production_fictional"
    end
  end
end
