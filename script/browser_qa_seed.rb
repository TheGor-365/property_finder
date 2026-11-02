# One-off GitHub Actions browser fixture. Never run against a user database.
require "json"
require "securerandom"
require "fileutils"

database = ActiveRecord::Base.connection_db_config.database.to_s
abort "STOP: CI-only test environment required" unless
  Rails.env.test? &&
  database.downcase.include?("test") &&
  ENV["GITHUB_ACTIONS"] == "true" &&
  ENV["PF_BROWSER_QA"] == "1"

abort "STOP: fixture database not empty" unless Account.count.zero? && Property.count.zero?

email = "browser-qa-#{SecureRandom.hex(8)}@example.invalid"
password = SecureRandom.urlsafe_base64(36)
agent = Account.create!(
  email: email,
  password: password,
  password_confirmation: password,
  first_name: "Demo",
  last_name: "QA Agent",
  company: "Property Finder automated demonstration",
  details: "Fictional agent for isolated GitHub Actions browser testing. No real homes or brokerage services."
)

property = Property.create!(
  account: agent,
  name: "DEMO - Browser QA Townhouse",
  address: "42 Fictional Street, Example City",
  price: 245_000,
  for_sale: true,
  status: "available",
  rooms: 3,
  bathrooms: 2,
  parking_spaces: 1,
  details: "Fictional home for automated browser acceptance only. No real property is being offered."
)

Property.create!(
  account: agent,
  name: "DEMO - Browser QA Rental",
  address: "10 Example Avenue, Fictional City",
  price: 1600,
  for_sale: false,
  status: "available",
  rooms: 2,
  bathrooms: 1,
  parking_spaces: 0
)

dir = Rails.root.join("tmp", "browser_qa")
FileUtils.mkdir_p(dir)
credentials = dir.join("credentials.json")
File.write(credentials, JSON.generate({
  email: email,
  password: password,
  property_id: property.id,
  agent_id: agent.id
}))
File.chmod(0600, credentials)
puts "BROWSER_QA_FIXTURE=READY"
puts "BROWSER_QA_SCOPE=GITHUB_ACTIONS_TEST_ONLY"
puts "BROWSER_QA_LISTINGS=2"
