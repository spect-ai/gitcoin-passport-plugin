class CreateUserPassportScoreTable < ActiveRecord::Migration[6.0]
  def change
    create_table :user_passport_score do |t|
      t.float :required_score, null: false
      t.references :user, null: false, foreign_key: true
      t.references :user_action, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_passport_score, [:user_action_id, :user_id], unique: true
  end
end
