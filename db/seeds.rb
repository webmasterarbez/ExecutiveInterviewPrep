# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

executive = User.find_or_create_by!(email: "user@test.com") do |user|
  user.password = "test123"
  user.timezone = "America/New_York"
  user.admin = false
end

executive.update!(name: "Jordan Blake", phone_number: "+12125550123") if executive.name.blank?

# admin@test.com intentionally has no interview requests so the dashboard
# empty state stays demonstrable.
User.find_or_create_by!(email: "admin@test.com") do |user|
  user.password = "test123"
  user.timezone = "America/New_York"
  user.admin = true
end

[
  {
    meeting_title: "Board interview with Acme Robotics",
    company_name: "Acme Robotics",
    contact_person_name: "Dana Whitfield",
    contact_person_title: "Chief Executive Officer",
    meeting_date: 3.days.from_now.change(hour: 14),
    status: "intake_review",
    executive_objectives: "Land the independent board seat; establish credibility on AI strategy."
  },
  {
    meeting_title: "Partnership pitch to Northwind Capital",
    company_name: "Northwind Capital",
    contact_person_name: "Miguel Santos",
    contact_person_title: "Managing Partner",
    meeting_date: 5.days.from_now.change(hour: 10),
    status: "pending_research"
  },
  {
    meeting_title: "Press interview with TechCrunch",
    company_name: "TechCrunch",
    contact_person_name: "Priya Raman",
    contact_person_title: "Senior Reporter",
    meeting_date: 2.days.from_now.change(hour: 9),
    status: "researching"
  },
  {
    meeting_title: "Keynote prep with Summit Conferences",
    company_name: "Summit Conferences",
    contact_person_name: "Lee Tanaka",
    contact_person_title: "Program Director",
    meeting_date: 10.days.from_now.change(hour: 16),
    status: "briefing_ready"
  },
  {
    meeting_title: "Coffee with Meridian Health CFO",
    company_name: "Meridian Health",
    contact_person_name: "Alex Osei",
    contact_person_title: "Chief Financial Officer",
    meeting_date: 1.day.ago.change(hour: 8),
    status: "completed"
  },
  {
    meeting_title: "Advisory call with Quantum Logistics",
    company_name: "Quantum Logistics",
    contact_person_name: "Sam Carver",
    contact_person_title: "VP of Operations",
    meeting_date: 7.days.from_now.change(hour: 11),
    status: "failed",
    error_message: "Research could not be completed: the research provider returned repeated errors. Please retry."
  }
].each do |attrs|
  executive.interview_requests.find_or_create_by!(meeting_title: attrs[:meeting_title]) do |request|
    request.assign_attributes(attrs)
  end
end
