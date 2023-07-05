class CreateCategoryPassportScoreTable < ActiveRecord::Migration[6.0]
  def change
    create_table :category_passport_score do |t|
      t.float :required_score, null: false
      t.references :category, null: false, foreign_key: true
      t.references :user_action, null: false, foreign_key: true

      t.timestamps
    end

    add_index :category_passport_score, [:user_action_id, :category_id], unique: true
  end
end
