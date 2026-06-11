# frozen_string_literal: true

module Webhooks
  # Receives ElevenLabs post-call webhooks. Raw (non-Inertia) endpoint:
  # CSRF-exempt, unauthenticated, authenticated instead by the HMAC signature
  # in the ElevenLabs-Signature header.
  class ElevenlabsController < ApplicationController
    SIGNATURE_TOLERANCE = 30.minutes

    allow_unauthenticated_access
    skip_before_action :verify_authenticity_token

    def create
      return head :unauthorized unless valid_signature?

      payload = JSON.parse(request.raw_post)
      return head :ok unless payload["type"] == "post_call_transcription"

      data = payload["data"] || {}
      conversation_id = data["conversation_id"]
      return head :ok if conversation_id.blank?

      user = User.find_by(phone_number: caller_number(data))
      if user.nil?
        Rails.logger.info("ElevenLabs webhook: no user matches caller for conversation #{conversation_id}")
        return head :ok
      end

      create_interview_request(user, conversation_id, data)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def valid_signature?
      header = request.headers["ElevenLabs-Signature"].to_s
      timestamp = header[/(?<=\bt=)\d+/]
      signature = header.split(",").find { |part| part.start_with?("v0=") }
      return false if timestamp.blank? || signature.blank?
      return false if Time.at(timestamp.to_i) < SIGNATURE_TOLERANCE.ago

      digest = "v0=" + OpenSSL::HMAC.hexdigest(
        "SHA256",
        ENV.fetch("ELEVENLABS_WEBHOOK_SECRET"),
        "#{timestamp}.#{request.raw_post}"
      )
      ActiveSupport::SecurityUtils.secure_compare(signature, digest)
    end

    def caller_number(data)
      data.dig("metadata", "phone_call", "external_number").presence ||
        data.dig("conversation_initiation_client_data", "dynamic_variables", "system__caller_id")
    end

    def create_interview_request(user, conversation_id, data)
      collected = collected_fields(data)

      user.interview_requests.find_or_create_by!(elevenlabs_conversation_id: conversation_id) do |request|
        request.meeting_title = collected["meeting_title"]
        request.meeting_date = parse_meeting_date(collected["meeting_date"])
        request.company_name = collected["company_name"]
        request.contact_person_name = collected["contact_person_name"]
        request.contact_person_title = collected["contact_person_title"]
        request.executive_objectives = collected["executive_objectives"]
        request.executive_context = collected["executive_context"]
        request.call_transcript = format_transcript(data["transcript"])
        request.audio_recording_url = "https://elevenlabs.io/app/agents/history/#{conversation_id}"
      end
    rescue ActiveRecord::RecordNotUnique
      # Re-delivered webhook raced a concurrent delivery; the request already exists.
    end

    def collected_fields(data)
      results = data.dig("analysis", "data_collection_results") || {}
      results.transform_values { |result| result.is_a?(Hash) ? result["value"] : result }
    end

    def parse_meeting_date(value)
      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def format_transcript(turns)
      Array(turns).filter_map do |turn|
        message = turn["message"]
        next if message.blank?

        speaker = turn["role"] == "agent" ? "Agent" : "You"
        "#{speaker}: #{message}"
      end.join("\n\n")
    end
  end
end
