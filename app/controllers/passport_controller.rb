# frozen_string_literal: true

module ::DiscourseGitcoinPassport
  class PassportController < ::ApplicationController
    requires_plugin DiscourseGitcoinPassport::PLUGIN_NAME

    before_action :ensure_gitcoin_passport_enabled

    def show
      begin
        render json: {
                  user_passport: UserPassportScore.where(user_id: current_user.id, user_action_type: action_id).first
        }
      rescue GitcoinPassport::Error => e
        render_json_error e.message
      end
    end

    def score
      begin
        render json: {
                 score: DiscourseGitcoinPassport::Passport.score("", SiteSetting.gitcoin_passport_scorer_id)
               }
      rescue GitcoinPassport::Error => e
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


        user_passport = UserPassportScore.new
        puts 'saveUserScore 4'

        user_passport.required_score = params[:score]
        user_passport.user_id = params[:user_id]
        user_passport.user_action_type = params[:action_id]
        puts 'saveUserScore 5'

        user_passport.save
        render json: {
                  user_passport: user_passport
               }
      rescue GitcoinPassport::Error => e
        render_json_error e.message
      end
    end

    def saveCategoryScore
      begin
        params.require(:category_id)
        params.permit(:score)
        params.permit(:action_id)

        render json: { status: 403, error: "You must be logged in to access this resource" } if !current_user
        render json: { status: 403, error: "You must be an admin to access this resource" } if !current_user.admin?

        user_passport = CategoryPassportScore.new
        puts 'saveUserScore 4'

        user_passport.required_score = params[:score]
        user_passport.category_id = params[:category_id]
        user_passport.user_action_type = params[:action_id]
        puts 'saveUserScore 5'

        user_passport.save
        render json: {
                  user_passport: user_passport
               }
      rescue GitcoinPassport::Error => e
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
