class CreateSearchQueries < ActiveRecord::Migration[8.1]
  def change
    create_table :search_queries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :terms, limit: 2000, null: false

      t.timestamps

      t.index %i[ user_id terms ]
    end
  end
end
