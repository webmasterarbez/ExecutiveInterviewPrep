# frozen_string_literal: true

class CreateFollowUpQas < ActiveRecord::Migration[8.0]
  def change
    create_table :follow_up_qas do |t|
      t.references :interview_request, null: false, foreign_key: true
      t.text :question
      t.text :answer

      t.timestamps
    end
  end
end
