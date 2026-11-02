require "securerandom"

namespace :pf do
  namespace :demo do
    def verified_demo_agent!
      database = ActiveRecord::Base.connection_db_config.database.to_s
      abort "STOP: test environment required" unless Rails.env.test? &&
        database.downcase.include?("test")

      agent = Account.find_by(email: "pf-catalog-showcase@example.invalid")
      abort "STOP: demonstration agent is missing" unless agent &&
        agent.first_name == "Demo" && agent.last_name == "Agent"

      names = Property.where(account_id: agent.id).pluck(:name)
      abort "STOP: unexpected demo listings" unless names.size == 12 &&
        names.all? { |name| name.to_s.start_with?("DEMO -") }

      abort "STOP: enquiries table is missing" unless Enquiry.table_exists?
      agent
    end

    desc "Generate one-time local DEMO agent password in an isolated Rails test DB"
    task grant_access: :environment do
      agent = verified_demo_agent!
      password = SecureRandom.urlsafe_base64(32)
      agent.update!(password: password, password_confirmation: password)
      abort "STOP: password verification failed" unless agent.reload.valid_password?(password)

      puts "DEMO_AGENT_ACCESS=GRANTED"
      puts "DEMO_LOGIN_EMAIL=#{agent.email}"
      puts "DEMO_TEMP_PASSWORD=#{password}"
      puts "Use only on 127.0.0.1 in your isolated Rails test environment."
      puts "Do not paste this password into chat, issues or commits."
    end

    desc "Revoke temporary DEMO login by rotating to a secret not printed or stored"
    task revoke_access: :environment do
      agent = verified_demo_agent!
      password = SecureRandom.urlsafe_base64(48)
      agent.update!(password: password, password_confirmation: password)
      abort "STOP: revoke verification failed" unless agent.reload.valid_password?(password)

      puts "DEMO_AGENT_ACCESS=REVOKED"
      puts "ENVIRONMENT=test"
    end
  end
end
