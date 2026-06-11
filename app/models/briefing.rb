# frozen_string_literal: true

class Briefing < ApplicationRecord
  belongs_to :interview_request

  validates :interview_request_id, uniqueness: true
end
