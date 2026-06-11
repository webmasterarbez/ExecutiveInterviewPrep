# frozen_string_literal: true

class CreateResearchData < ActiveRecord::Migration[8.0]
  def change
    create_table :research_data do |t|
      t.references :interview_request, null: false, foreign_key: true, index: { unique: true }
      t.text :company_overview
      t.text :company_news
      t.text :person_bio
      t.text :person_social_profiles
      t.text :industry_context
      t.text :research_sources

      t.timestamps
    end
  end
end
