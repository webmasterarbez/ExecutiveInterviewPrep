require "test_helper"

module Webhooks
  class ElevenlabsControllerTest < ActionDispatch::IntegrationTest
    SECRET = "test-webhook-secret"

    setup do
      @user = users(:one) # phone_number +12125550123
      ENV["ELEVENLABS_WEBHOOK_SECRET"] = SECRET
    end

    teardown do
      ENV.delete("ELEVENLABS_WEBHOOK_SECRET")
    end

    test "creates an interview request from a signed transcription webhook" do
      body = payload(conversation_id: "conv_123").to_json

      assert_difference -> { InterviewRequest.count }, 1 do
        post_webhook body
      end

      assert_response :ok
      request = InterviewRequest.find_by(elevenlabs_conversation_id: "conv_123")
      assert_equal @user, request.user
      assert_equal "intake_review", request.status
      assert_equal "Board interview with Globex", request.meeting_title
      assert_equal "Globex", request.company_name
      assert_equal "Hank Scorpio", request.contact_person_name
      assert_equal "CEO", request.contact_person_title
      assert_equal "Land the board seat", request.executive_objectives
      assert_equal Time.zone.parse("2026-06-20T14:00"), request.meeting_date
      assert_includes request.call_transcript, "Agent: What meeting are you preparing for?"
      assert_includes request.call_transcript, "You: A board interview with Globex."
      assert_equal "https://elevenlabs.io/app/agents/history/conv_123", request.audio_recording_url
    end

    test "is idempotent across re-delivered webhooks" do
      body = payload(conversation_id: "conv_dup").to_json

      assert_difference -> { InterviewRequest.count }, 1 do
        post_webhook body
        post_webhook body
      end

      assert_response :ok
    end

    test "rejects an invalid signature" do
      body = payload.to_json

      assert_no_difference -> { InterviewRequest.count } do
        post "/webhooks/elevenlabs", params: body,
             headers: { "Content-Type" => "application/json",
                        "ElevenLabs-Signature" => "t=#{Time.now.to_i},v0=deadbeef" }
      end

      assert_response :unauthorized
    end

    test "rejects a missing signature header" do
      assert_no_difference -> { InterviewRequest.count } do
        post "/webhooks/elevenlabs", params: payload.to_json,
             headers: { "Content-Type" => "application/json" }
      end

      assert_response :unauthorized
    end

    test "rejects a stale timestamp" do
      body = payload.to_json
      stale = 31.minutes.ago.to_i

      assert_no_difference -> { InterviewRequest.count } do
        post "/webhooks/elevenlabs", params: body,
             headers: { "Content-Type" => "application/json",
                        "ElevenLabs-Signature" => signature_header(body, timestamp: stale) }
      end

      assert_response :unauthorized
    end

    test "acks but ignores calls from unknown numbers" do
      body = payload(caller: "+19998887777").to_json

      assert_no_difference -> { InterviewRequest.count } do
        post_webhook body
      end

      assert_response :ok
    end

    test "acks but ignores non-transcription webhook types" do
      body = { type: "post_call_audio", data: { conversation_id: "conv_audio" } }.to_json

      assert_no_difference -> { InterviewRequest.count } do
        post_webhook body
      end

      assert_response :ok
    end

    test "rejects malformed JSON" do
      post_webhook "not json{"

      assert_response :bad_request
    end

    private

    def post_webhook(body)
      post "/webhooks/elevenlabs", params: body,
           headers: { "Content-Type" => "application/json",
                      "ElevenLabs-Signature" => signature_header(body) }
    end

    def signature_header(body, timestamp: Time.now.to_i)
      digest = OpenSSL::HMAC.hexdigest("SHA256", SECRET, "#{timestamp}.#{body}")
      "t=#{timestamp},v0=#{digest}"
    end

    def payload(conversation_id: "conv_abc", caller: "+12125550123")
      {
        type: "post_call_transcription",
        event_timestamp: Time.now.to_i,
        data: {
          conversation_id: conversation_id,
          agent_id: "agent_1",
          transcript: [
            { role: "agent", message: "What meeting are you preparing for?" },
            { role: "user", message: "A board interview with Globex." }
          ],
          metadata: {
            phone_call: { external_number: caller, direction: "inbound" }
          },
          analysis: {
            data_collection_results: {
              meeting_title: { value: "Board interview with Globex" },
              company_name: { value: "Globex" },
              contact_person_name: { value: "Hank Scorpio" },
              contact_person_title: { value: "CEO" },
              meeting_date: { value: "2026-06-20T14:00" },
              executive_objectives: { value: "Land the board seat" },
              executive_context: { value: "Interview; second round" }
            }
          }
        }
      }
    end
  end
end
