# frozen_string_literal: true

module ::DiscourseGitcoinPassport
  class PassportController < ::ApplicationController
    requires_plugin DiscourseGitcoinPassport::PLUGIN_NAME

    before_action :ensure_gitcoin_passport_enabled

    def show
      begin
        render json: {
                  user_passport_score: UserPassportScore.where(user_id: current_user.id, user_action_type: action_id).first
        }
      rescue DiscourseGitcoinPassport::Error => e
        render_json_error e.message
      end
    end

    def score
      begin
        render json: {
                 score: DiscourseGitcoinPassport::Passport.score("", SiteSetting.gitcoin_passport_scorer_id)
               }
      rescue DiscourseGitcoinPassport::Error => e
        render_json_error e.message
      end
    end

    def saveUserScore
      begin
        puts "saveUserScore"
        puts params[:user_id]

        params.require(:user_id)
        params.require(:score)
        params.require(:action_id)

        puts 'saveUserScore 2'
        render json: { status: 403, error: "You must be logged in to access this resource" } if !current_user
        render json: { status: 403, error: "You must be an admin to access this resource" } if !current_user.admin?

        puts 'saveUserScore 3'
        user_passport_score = UserPassportScore.where(user_id: params[:user_id], user_action_type: params[:action_id])
        if user_passport_score.exists?
          user_passport_score.first.required_score = params[:score]
          user_passport_score.first.save
          render json: {
            user_passport_score: user_passport_score.first
          }
        else
          user_passport_score = UserPassportScore.new
          puts 'saveUserScore 4'

          user_passport_score.required_score = params[:score]
          user_passport_score.user_id = params[:user_id]
          user_passport_score.user_action_type = params[:action_id]
          puts 'saveUserScore 5'

          user_passport_score.save
          render json: {
                    user_passport_score: user_passport_score
                }
        end
      rescue DiscourseGitcoinPassport::Error => e
        render_json_error e.message
      end
    end

    def saveCategoryScore
      begin
        params.require(:category_id)
        params.require(:score)
        params.require(:action_id)

        render json: { status: 403, error: "You must be logged in to access this resource" } if !current_user
        render json: { status: 403, error: "You must be an admin to access this resource" } if !current_user.admin?

        category_passport_score = CategoryPassportScore.where(category_id: params[:category_id], user_action_type: params[:action_id])

        puts category_passport_score.exists?
        if (category_passport_score.exists?)
          category_passport_score.first.required_score = params[:score]
          category_passport_score.first.save
          render json: {
            category_passport_score: category_passport_score.first
          }
        else
          category_passport_score = CategoryPassportScore.new
          puts 'saveUserScore 4'

          category_passport_score.required_score = params[:score]
          category_passport_score.category_id = params[:category_id]
          category_passport_score.user_action_type = params[:action_id]
          puts 'saveUserScore 5'

          category_passport_score.save
          render json: {
              category_passport_score: category_passport_score
                }
        end
      rescue DiscourseGitcoinPassport::Error => e
        render_json_error e.message
      end
    end




    def ensure_gitcoin_passport_enabled
      if !SiteSetting.gitcoin_passport_enabled
        raise Discourse::InvalidAccess.new("Gitcoin Passport is not enabled")
      end
    end
  end
end
