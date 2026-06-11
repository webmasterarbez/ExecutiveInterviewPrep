require "test_helper"

class ResearchDataTest < ActiveSupport::TestCase
  test "belongs to an interview request" do
    assert_equal interview_requests(:northwind_pitch), research_data(:northwind_research).interview_request
  end

  test "allows only one research data per interview request" do
    duplicate = ResearchData.new(interview_request: interview_requests(:northwind_pitch))

    assert_not duplicate.valid?
    assert duplicate.errors[:interview_request_id].present?
  end
end
