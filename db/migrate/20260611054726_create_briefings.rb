# frozen_string_literal: true

class CreateBriefings < ActiveRecord::Migration[8.0]
  def change
    create_table :briefings do |t|
      t.references :interview_request, null: false, foreign_key: true, index: { unique: true }
      t.text :talking_points
      t.text :likely_questions
      t.text :opportunities
      t.text :risks
      t.text :key_facts
      t.datetime :callback_completed_at

      t.timestamps
    end
  end
end
