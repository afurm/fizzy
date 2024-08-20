class RemoveUnnecessaryColumnsFromSessions < ActiveRecord::Migration[8.0]
  def change
    change_table :sessions do |t|
      t.remove :last_active_at
      t.remove :token
    end
  end
end
