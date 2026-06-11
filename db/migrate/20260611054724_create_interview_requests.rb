# frozen_string_literal: true

class CreateInterviewRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :interview_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :meeting_title
      t.datetime :meeting_date
      t.string :company_name
      t.string :contact_person_name
      t.string :contact_person_title
      t.text :contact_person_background
      t.text :executive_context
      t.text :executive_objectives
      t.text :call_transcript
      t.string :audio_recording_url
      t.string :status, null: false, default: "intake_review"
      t.text :error_message

      t.timestamps
    end
  end
end
