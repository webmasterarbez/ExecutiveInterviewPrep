require "test_helper"

class InterviewRequestTest < ActiveSupport::TestCase
  test "belongs to a user" do
    assert_equal users(:one), interview_requests(:acme_board).user
  end

  test "requires a user" do
    request = InterviewRequest.new(meeting_title: "No owner")

    assert_not request.valid?
    assert request.errors[:user].present?
  end

  test "defaults status to intake_review" do
    request = users(:two).interview_requests.create!(meeting_title: "Defaults check")

    assert_equal "intake_review", request.status
  end

  test "accepts every lifecycle status" do
    request = interview_requests(:acme_board)

    %w[intake_review pending_research researching briefing_ready completed failed].each do |status|
      request.status = status
      assert request.valid?, "expected #{status} to be valid"
    end
  end

  test "rejects an unknown status" do
    request = interview_requests(:acme_board)
    request.status = "bogus"

    assert_not request.valid?
    assert request.errors[:status].present?
  end

  test "exposes status predicate helpers" do
    assert interview_requests(:acme_board).intake_review?
    assert interview_requests(:northwind_pitch).briefing_ready?
    assert interview_requests(:failed_request).failed?
  end

  test "has one research data and one briefing" do
    request = interview_requests(:northwind_pitch)

    assert_equal research_data(:northwind_research), request.research_data
    assert_equal briefings(:northwind_briefing), request.briefing
  end

  test "has many follow up qas" do
    assert_includes interview_requests(:northwind_pitch).follow_up_qas, follow_up_qas(:northwind_question)
  end

  test "destroys dependent research data, briefing, and follow up qas" do
    request = interview_requests(:northwind_pitch)

    assert_difference [ "ResearchData.count", "Briefing.count", "FollowUpQa.count" ], -1 do
      request.destroy
    end
  end
end
