# frozen_string_literal: true

# Researches a confirmed Interview Request via Perplexity (company, news,
# person, industry), stores the results, and hands off to SynthesisJob.
# Idempotent: re-runs overwrite the same ResearchData row.
class ResearchJob < ApplicationJob
  queue_as :default

  # Declaration order matters: later handlers win, so retry_on must come after
  # rescue_from for TransientError (a subclass of Error) to reach the retry path.
  rescue_from PerplexityClient::Error, KeyError do |error|
    mark_failed(arguments.first, "Research could not be completed: #{error.message}. Please retry.")
  end

  retry_on PerplexityClient::TransientError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:mark_failed, job.arguments.first,
             "Research could not be completed: the research provider kept returning errors (#{error.message}). Please retry.")
  end

  def perform(interview_request)
    return unless interview_request.pending_research? || interview_request.researching?

    interview_request.update!(status: :researching)

    client = PerplexityClient.new
    company = client.research(company_prompt(interview_request))
    news = client.research(news_prompt(interview_request))
    person = client.research(person_prompt(interview_request))
    industry = client.research(industry_prompt(interview_request))

    research = ResearchData.find_or_initialize_by(interview_request: interview_request)
    research.update!(
      company_overview: company[:content],
      company_news: news[:content],
      person_bio: person[:content],
      person_social_profiles: social_profiles(person[:sources]),
      industry_context: industry[:content],
      research_sources: format_sources(company, news, person, industry)
    )

    SynthesisJob.perform_later(interview_request)
  end

  private

  def company_prompt(request)
    <<~PROMPT
      Research the company "#{request.company_name}": what it does, size, structure,
      market position, leadership, and any recent strategic announcements.
      Context: an executive is preparing for "#{request.meeting_title}".
    PROMPT
  end

  def news_prompt(request)
    <<~PROMPT
      Find recent news about "#{request.company_name}" from the last 6 months:
      press releases, funding or financial results, product launches, leadership
      changes, and notable market moves.
    PROMPT
  end

  def person_prompt(request)
    <<~PROMPT
      Research #{request.contact_person_name} (#{request.contact_person_title} at
      #{request.company_name}): career history, education, public statements,
      interests, and public profiles (LinkedIn, X/Twitter, etc.).
      #{"Known background: #{request.contact_person_background}" if request.contact_person_background.present?}
    PROMPT
  end

  def industry_prompt(request)
    <<~PROMPT
      Summarize the industry context for "#{request.company_name}": key market
      trends, competitive landscape, regulatory or technology shifts, and the
      main challenges companies in this space face right now.
    PROMPT
  end

  def social_profiles(sources)
    profiles = sources.select { |s| s[:url] =~ /linkedin\.com|twitter\.com|x\.com/i }
    profiles = sources.first(3) if profiles.empty?
    profiles.map { |s| "#{s[:title]} — #{s[:url]}" }.join("\n")
  end

  def format_sources(*results)
    results.flat_map { |r| r[:sources] }
           .uniq { |s| s[:url] }
           .map { |s| "#{s[:title]} — #{s[:url]}" }
           .join("\n")
  end

  def mark_failed(interview_request, message)
    interview_request.update!(status: :failed, error_message: message)
  end
end
