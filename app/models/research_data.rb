# frozen_string_literal: true

class ResearchData < ApplicationRecord
  belongs_to :interview_request

  validates :interview_request_id, uniqueness: true
end
