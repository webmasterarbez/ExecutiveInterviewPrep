# frozen_string_literal: true

class InterviewRequest < ApplicationRecord
  belongs_to :user
  has_one :research_data, dependent: :destroy
  has_one :briefing, dependent: :destroy
  has_many :follow_up_qas, dependent: :destroy

  enum :status, {
    intake_review: "intake_review",
    pending_research: "pending_research",
    researching: "researching",
    briefing_ready: "briefing_ready",
    completed: "completed",
    failed: "failed"
  }, validate: true
end
