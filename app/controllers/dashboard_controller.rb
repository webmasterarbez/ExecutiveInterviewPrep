class DashboardController < ApplicationController
  def show
    render inertia: "Dashboard", props: {
      interview_requests: Current.user.interview_requests.order(created_at: :desc).map do |request|
        {
          id: request.id,
          meeting_title: request.meeting_title,
          company_name: request.company_name,
          contact_person_name: request.contact_person_name,
          meeting_date: request.meeting_date&.iso8601,
          status: request.status,
          error_message: request.error_message,
          created_at: request.created_at.iso8601
        }
      end
    }
  end
end
