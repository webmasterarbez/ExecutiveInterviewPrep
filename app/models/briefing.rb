# frozen_string_literal: true

class Briefing < ApplicationRecord
  belongs_to :interview_request

  serialize :talking_points, coder: JSON
  serialize :likely_questions, coder: JSON
  serialize :opportunities, coder: JSON
  serialize :risks, coder: JSON
  serialize :key_facts, coder: JSON

  validates :interview_request_id, uniqueness: true
end
