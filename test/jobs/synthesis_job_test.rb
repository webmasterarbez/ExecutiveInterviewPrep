require "test_helper"
require "minitest/mock"

class SynthesisJobTest < ActiveJob::TestCase
  SECTIONS = {
    "talking_points" => [
      { "point" => "Lead with the robotics track record",
        "detail" => "Open with the automation results",
        "supporting_research" => "Acme shipped 2 new robot lines this year" }
    ],
    "likely_questions" => [
      { "topic" => "Strategy", "question" => "Why now?",
        "suggested_context" => "Tie to market timing",
        "supporting_research" => "Industry consolidation is accelerating" }
    ],
    "opportunities" => [ { "title" => "Board seat", "detail" => "Push for the open seat" } ],
    "risks" => [ { "title" => "Valuation talk", "detail" => "Avoid anchoring early" } ],
    "key_facts" => [ "Acme has 1,200 employees" ]
  }.freeze

  setup do
    @request = interview_requests(:acme_board)
    @request.update!(status: :researching)
    ResearchData.create!(
      interview_request: @request,
      company_overview: "Acme overview",
      company_news: "Acme news",
      person_bio: "Dana bio",
      industry_context: "Robotics trends"
    )
  end

  test "creates the briefing and marks the request briefing ready" do
    stub_claude(SECTIONS.to_json) do
      SynthesisJob.perform_now(@request)
    end

    @request.reload
    assert_equal "briefing_ready", @request.status

    briefing = @request.briefing
    assert_equal "Lead with the robotics track record", briefing.talking_points.first["point"]
    assert_equal "Strategy", briefing.likely_questions.first["topic"]
    assert_equal [ "Acme has 1,200 employees" ], briefing.key_facts
  end

  test "re-running overwrites the same briefing row" do
    stub_claude(SECTIONS.to_json) { SynthesisJob.perform_now(@request) }

    @request.update!(status: :researching)
    changed = SECTIONS.merge("key_facts" => [ "Updated fact" ])

    assert_no_difference -> { Briefing.count } do
      stub_claude(changed.to_json) { SynthesisJob.perform_now(@request) }
    end

    assert_equal [ "Updated fact" ], @request.reload.briefing.key_facts
  end

  test "no-ops when the request is not researching" do
    @request.update!(status: :completed)

    SynthesisJob.perform_now(@request)

    assert_nil @request.reload.briefing
  end

  test "no-ops when research data is missing" do
    @request.research_data.destroy!
    @request.reload

    SynthesisJob.perform_now(@request)

    assert_equal "researching", @request.reload.status
    assert_nil @request.briefing
  end

  test "unparseable synthesis output marks the request failed" do
    stub_claude("not json{") do
      SynthesisJob.perform_now(@request)
    end

    @request.reload
    assert_equal "failed", @request.status
    assert_includes @request.error_message, "Briefing synthesis could not be completed"
  end

  private

  # Stubs Anthropic::Client.new to return a double whose messages.create
  # yields a single text block containing `text`.
  def stub_claude(text, &block)
    block_double = Struct.new(:type, :text).new(:text, text)
    message = Struct.new(:content).new([ block_double ])
    messages = Object.new
    messages.define_singleton_method(:create) { |**_kwargs| message }
    client = Struct.new(:messages).new(messages)

    ENV["ANTHROPIC_API_KEY"] = "test-key"
    Anthropic::Client.stub(:new, client, &block)
  ensure
    ENV.delete("ANTHROPIC_API_KEY")
  end
end
