# frozen_string_literal: true

# Synthesizes stored research into a Briefing via Claude (structured output),
# then marks the Interview Request briefing_ready. Idempotent: re-runs
# overwrite the same Briefing row.
class SynthesisJob < ApplicationJob
  queue_as :default

  MODEL = "claude-opus-4-8"

  TRANSIENT_ERRORS = [
    Anthropic::Errors::RateLimitError,
    Anthropic::Errors::InternalServerError,
    Anthropic::Errors::APIConnectionError
  ].freeze

  BRIEFING_SCHEMA = {
    type: "object",
    additionalProperties: false,
    required: %w[talking_points likely_questions opportunities risks key_facts],
    properties: {
      talking_points: {
        type: "array",
        description: "5-10 key messages the executive should lead with",
        items: {
          type: "object",
          additionalProperties: false,
          required: %w[point detail supporting_research],
          properties: {
            point: { type: "string", description: "The talking point, one sentence" },
            detail: { type: "string", description: "How to deliver it and why it lands" },
            supporting_research: { type: "string", description: "The research facts backing this point" }
          }
        }
      },
      likely_questions: {
        type: "array",
        description: "Probable questions organized by topic",
        items: {
          type: "object",
          additionalProperties: false,
          required: %w[topic question suggested_context supporting_research],
          properties: {
            topic: { type: "string" },
            question: { type: "string" },
            suggested_context: { type: "string", description: "How the executive should approach answering" },
            supporting_research: { type: "string", description: "The research facts behind this question" }
          }
        }
      },
      opportunities: {
        type: "array",
        description: "Outcomes to push for, key wins to target",
        items: {
          type: "object",
          additionalProperties: false,
          required: %w[title detail],
          properties: { title: { type: "string" }, detail: { type: "string" } }
        }
      },
      risks: {
        type: "array",
        description: "Potential pitfalls, topics to tread carefully on",
        items: {
          type: "object",
          additionalProperties: false,
          required: %w[title detail],
          properties: { title: { type: "string" }, detail: { type: "string" } }
        }
      },
      key_facts: {
        type: "array",
        description: "Quick-reference facts about the company and person",
        items: { type: "string" }
      }
    }
  }.freeze

  # Declaration order matters: later handlers win, so retry_on must come after
  # rescue_from for the transient subclasses of APIError to reach the retry path.
  rescue_from Anthropic::Errors::APIError, JSON::ParserError, KeyError do |error|
    mark_failed(arguments.first, "Briefing synthesis could not be completed: #{error.message}. Please retry.")
  end

  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 3) do |job, error|
    job.send(:mark_failed, job.arguments.first,
             "Briefing synthesis could not be completed: the synthesis provider kept returning errors (#{error.message}). Please retry.")
  end

  def perform(interview_request)
    return unless interview_request.researching?

    research = interview_request.research_data
    return if research.nil?

    sections = synthesize(interview_request, research)

    briefing = Briefing.find_or_initialize_by(interview_request: interview_request)
    briefing.update!(
      talking_points: sections.fetch("talking_points"),
      likely_questions: sections.fetch("likely_questions"),
      opportunities: sections.fetch("opportunities"),
      risks: sections.fetch("risks"),
      key_facts: sections.fetch("key_facts")
    )

    interview_request.update!(status: :briefing_ready)
  end

  private

  def synthesize(interview_request, research)
    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

    message = client.messages.create(
      model: MODEL,
      max_tokens: 16_000,
      thinking: { type: :adaptive },
      output_config: { format_: { type: :json_schema, schema: BRIEFING_SCHEMA } },
      system_: system_prompt,
      messages: [ { role: :user, content: user_prompt(interview_request, research) } ]
    )

    text = message.content.find { |block| block.type == :text }
    raise JSON::ParserError, "no text block in synthesis response" if text.nil?

    JSON.parse(text.text)
  end

  def system_prompt
    "You are an executive briefing strategist. You turn raw research into sharp, " \
    "actionable meeting preparation: talking points, likely questions, opportunities, " \
    "risks, and key facts. Be specific to this meeting — never generic. Ground every " \
    "item in the research provided."
  end

  def user_prompt(request, research)
    <<~PROMPT
      Prepare a briefing for this meeting.

      ## Meeting
      - Title: #{request.meeting_title}
      - Date: #{request.meeting_date}
      - Company: #{request.company_name}
      - Meeting with: #{request.contact_person_name} (#{request.contact_person_title})
      - Executive's objectives: #{request.executive_objectives}
      - Additional context from the executive: #{request.executive_context}
      - Known background on the contact: #{request.contact_person_background}

      ## Research
      ### Company overview
      #{research.company_overview}

      ### Recent company news
      #{research.company_news}

      ### Contact person
      #{research.person_bio}

      ### Industry context
      #{research.industry_context}

      Produce 5-10 talking points, likely questions grouped by topic, opportunities,
      risks, and key facts, following the output schema exactly.
    PROMPT
  end

  def mark_failed(interview_request, message)
    interview_request.update!(status: :failed, error_message: message)
  end
end
