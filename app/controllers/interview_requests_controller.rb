# frozen_string_literal: true

class InterviewRequestsController < ApplicationController
  before_action :set_interview_request

  def show
    render inertia: "interview_requests/Show", props: {
      interview_request: {
        id: @interview_request.id,
        meeting_title: @interview_request.meeting_title,
        meeting_date: @interview_request.meeting_date&.iso8601,
        company_name: @interview_request.company_name,
        contact_person_name: @interview_request.contact_person_name,
        contact_person_title: @interview_request.contact_person_title,
        contact_person_background: @interview_request.contact_person_background,
        executive_context: @interview_request.executive_context,
        executive_objectives: @interview_request.executive_objectives,
        call_transcript: @interview_request.call_transcript,
        audio_recording_url: @interview_request.audio_recording_url,
        status: @interview_request.status,
        error_message: @interview_request.error_message,
        created_at: @interview_request.created_at.iso8601
      },
      briefing: briefing_props,
      research: research_props
    }
  end

  def update
    unless @interview_request.intake_review?
      return redirect_to interview_request_path(@interview_request),
                         alert: "Details can only be edited while the request is awaiting review."
    end

    if @interview_request.update(interview_request_params)
      redirect_to interview_request_path(@interview_request), notice: "Details saved."
    else
      redirect_to interview_request_path(@interview_request),
                  inertia: { errors: @interview_request.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def confirm
    unless @interview_request.intake_review?
      return redirect_to interview_request_path(@interview_request),
                         alert: "This request has already been confirmed."
    end

    @interview_request.update!(status: :pending_research)
    ResearchJob.perform_later(@interview_request)
    redirect_to interview_request_path(@interview_request),
                notice: "Details confirmed. Research is queued."
  end

  def retry
    unless @interview_request.failed?
      return redirect_to interview_request_path(@interview_request),
                         alert: "Only failed requests can be retried."
    end

    @interview_request.update!(status: :pending_research, error_message: nil)
    ResearchJob.perform_later(@interview_request)
    redirect_to interview_request_path(@interview_request),
                notice: "Retrying. Research is queued."
  end

  private

  def briefing_props
    briefing = @interview_request.briefing
    return nil if briefing.nil?

    {
      talking_points: briefing.talking_points || [],
      likely_questions: briefing.likely_questions || [],
      opportunities: briefing.opportunities || [],
      risks: briefing.risks || [],
      key_facts: briefing.key_facts || [],
      created_at: briefing.created_at.iso8601
    }
  end

  def research_props
    research = @interview_request.research_data
    return nil if research.nil?

    {
      company_overview: research.company_overview,
      company_news: research.company_news,
      person_bio: research.person_bio,
      person_social_profiles: research.person_social_profiles,
      industry_context: research.industry_context,
      research_sources: research.research_sources
    }
  end

  def set_interview_request
    @interview_request = Current.user.interview_requests.find(params[:id])
  end

  def interview_request_params
    params.permit(
      :meeting_title, :meeting_date, :company_name,
      :contact_person_name, :contact_person_title, :contact_person_background,
      :executive_context, :executive_objectives
    )
  end
end
