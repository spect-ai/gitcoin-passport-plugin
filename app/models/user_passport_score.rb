class UserPassportScore < ActiveRecord::Base
  belongs_to :user

  def has_user_level_score?(user)
    user&.id && passport_scores.where(user_id: user.id).exists?
  end

  def user_level_scores(user)
    return passport_scores.where(user_id: user.id)
  end

  def user_action_scores(user, action)
    return passport_scores.where(user_id: user.id, user_action_id: action.id)
  end
end



# == Schema Information
#
# Table name: user_passport_scores
#
#  id                     :integer           not null, primary key
#  required_score         :float            not null
#  user_id                :integer           not null
#  user_action_type       :integer           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_user_passport_score_on_action_id_user_id                           (user_action_type, user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => user.id)
#
