class CategoryPassportScore < ActiveRecord::Base
  belongs_to :category
  belongs_to :user_actions

  def has_category_level_score?(category)
    category&.id && passport_scores.where(category_id: category.id).exists?
  end

  def category_level_scores(category)
    return passport_scores.where(category_id: category.id)
  end

  def category_action_scores(category, action)
    return passport_scores.where(category_id: category.id, user_action_id: action.id)
  end
end



# == Schema Information
#
# Table name: category_passport_score
#
#  id             :bigint           not null, primary key
#  required_score :float            not null
#  category_id    :bigint           not null
#  user_action_id      :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_category_passport_score_on_action_id_category_id                      (user_action_id, category_id) UNIQUE
#  index_category_passport_score_on_category_id                                (category_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => category.id)
#  fk_rails_...  (user_action_id => user_actions.id)
#
