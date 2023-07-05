class CategoryPassportScore < ActiveRecord::Base
  belongs_to :category

  def has_category_level_score?(category)
    category&.id && passport_scores.where(category_id: category.id).exists?
  end

  def category_level_scores(category)
    return passport_scores.where(category_id: category.id)
  end

  def category_action_scores(category, action)
    return passport_scores.where(category_id: category.id, user_action_type: action.id)
  end
end



# == Schema Information
#
# Table name: category_passport_scores
#
#  id                    :integer           not null, primary key
#  required_score        :float            not null
#  category_id           :integer           not null
#  user_action_type      :integer           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_category_score_on_action_id_category_id                      (user_action_type, category_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (category_id => category.id)
#
