require "test_helper"
require "minitest/mock"

class ResearchJobTest < ActiveJob::TestCase
  setup do
    @request = interview_requests(:acme_board)
    @request.update!(status: :pending_research)
  end

  test "stores research, moves to researching, and enqueues synthesis" do
    client = fake_client(
      content: "Research findings.",
      sources: [
        { title: "Acme on LinkedIn", url: "https://linkedin.com/company/acme" },
        { title: "Acme news", url: "https://news.test/acme" }
      ]
    )

    PerplexityClient.stub(:new, client) do
      ResearchJob.perform_now(@request)
    end

    @request.reload
    assert_equal "researching", @request.status

    research = @request.research_data
    assert_equal "Research findings.", research.company_overview
    assert_equal "Research findings.", research.company_news
    assert_equal "Research findings.", research.person_bio
    assert_equal "Research findings.", research.industry_context
    assert_includes research.person_social_profiles, "linkedin.com/company/acme"
    assert_includes research.research_sources, "Acme news — https://news.test/acme"

    assert_enqueued_with(job: SynthesisJob, args: [ @request ])
  end

  test "re-running overwrites the same research data row" do
    client = fake_client(content: "First pass.", sources: [])

    PerplexityClient.stub(:new, client) do
      ResearchJob.perform_now(@request)
    end

    updated = fake_client(content: "Second pass.", sources: [])
    @request.update!(status: :researching)

    assert_no_difference -> { ResearchData.count } do
      PerplexityClient.stub(:new, updated) do
        ResearchJob.perform_now(@request)
      end
    end

    assert_equal "Second pass.", @request.reload.research_data.company_overview
  end

  test "no-ops when the request is not awaiting research" do
    @request.update!(status: :completed)

    ResearchJob.perform_now(@request)

    assert_nil @request.reload.research_data
    assert_equal "completed", @request.status
  end

  test "permanent error marks the request failed with a message" do
    client = Object.new
    def client.research(_prompt) = raise PerplexityClient::Error, "401 bad key"

    PerplexityClient.stub(:new, client) do
      ResearchJob.perform_now(@request)
    end

    @request.reload
    assert_equal "failed", @request.status
    assert_includes @request.error_message, "401 bad key"
  end

  test "transient error re-enqueues the job for retry" do
    client = Object.new
    def client.research(_prompt) = raise PerplexityClient::TransientError, "503"

    PerplexityClient.stub(:new, client) do
      ResearchJob.perform_now(@request)
    end

    assert_enqueued_with(job: ResearchJob)
    assert_not_equal "failed", @request.reload.status
  end

  private

  def fake_client(content:, sources:)
    client = Object.new
    client.define_singleton_method(:research) { |_prompt| { content: content, sources: sources } }
    client
  end
end
