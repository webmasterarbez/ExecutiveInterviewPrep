require "test_helper"

class BriefingTest < ActiveSupport::TestCase
  test "belongs to an interview request" do
    assert_equal interview_requests(:northwind_pitch), briefings(:northwind_briefing).interview_request
  end

  test "allows only one briefing per interview request" do
    duplicate = Briefing.new(interview_request: interview_requests(:northwind_pitch))

    assert_not duplicate.valid?
    assert duplicate.errors[:interview_request_id].present?
  end
end
