require "test_helper"

class FollowUpQaTest < ActiveSupport::TestCase
  test "belongs to an interview request" do
    assert_equal interview_requests(:northwind_pitch), follow_up_qas(:northwind_question).interview_request
  end

  test "is ordered within a callback session by created_at" do
    request = interview_requests(:northwind_pitch)
    later = request.follow_up_qas.create!(question: "Anything else?", answer: "No.")

    assert_equal later, request.follow_up_qas.order(:created_at).last
  end
end
