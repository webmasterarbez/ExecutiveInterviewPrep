# frozen_string_literal: true

class AddElevenlabsConversationIdToInterviewRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :interview_requests, :elevenlabs_conversation_id, :string
    add_index :interview_requests, :elevenlabs_conversation_id, unique: true
  end
end
