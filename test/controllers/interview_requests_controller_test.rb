require "test_helper"

class InterviewRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @request_record = interview_requests(:acme_board) # intake_review
    post login_path, params: { email: @user.email, password: "password" }
  end

  test "shows own interview request" do
    get interview_request_path(@request_record)

    assert_response :success
    assert_includes response.body, "Board interview with Acme Robotics"
  end

  test "404s on another user's interview request" do
    post login_path, params: { email: users(:two).email, password: "password" }

    get interview_request_path(@request_record)

    assert_response :not_found
  end

  test "updates details while in intake review" do
    patch interview_request_path(@request_record), params: {
      meeting_title: "Updated title",
      executive_context: "More context"
    }

    assert_redirected_to interview_request_path(@request_record)
    @request_record.reload
    assert_equal "Updated title", @request_record.meeting_title
    assert_equal "More context", @request_record.executive_context
  end

  test "rejects updates once past intake review" do
    confirmed = interview_requests(:northwind_pitch) # briefing_ready

    patch interview_request_path(confirmed), params: { meeting_title: "Nope" }

    assert_redirected_to interview_request_path(confirmed)
    assert_not_equal "Nope", confirmed.reload.meeting_title
  end

  test "confirm moves the request to pending research and enqueues the research job" do
    assert_enqueued_with(job: ResearchJob, args: [ @request_record ]) do
      post confirm_interview_request_path(@request_record)
    end

    assert_redirected_to interview_request_path(@request_record)
    assert_equal "pending_research", @request_record.reload.status
  end

  test "retry resets a failed request and re-enqueues research" do
    failed = interview_requests(:failed_request)

    assert_enqueued_with(job: ResearchJob, args: [ failed ]) do
      post retry_interview_request_path(failed)
    end

    assert_redirected_to interview_request_path(failed)
    failed.reload
    assert_equal "pending_research", failed.status
    assert_nil failed.error_message
  end

  test "retry is rejected for non-failed requests" do
    assert_no_enqueued_jobs only: ResearchJob do
      post retry_interview_request_path(@request_record)
    end

    assert_redirected_to interview_request_path(@request_record)
    assert_equal "intake_review", @request_record.reload.status
  end

  test "confirm is rejected outside intake review" do
    confirmed = interview_requests(:northwind_pitch)

    post confirm_interview_request_path(confirmed)

    assert_redirected_to interview_request_path(confirmed)
    assert_equal "briefing_ready", confirmed.reload.status
  end

  test "requires authentication" do
    delete logout_path

    get interview_request_path(@request_record)

    assert_redirected_to login_path
  end
end
