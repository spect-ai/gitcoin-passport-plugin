# frozen_string_literal: true

# name: discourse-gitcoin-passport
# about: A discourse plugin to enable users to manage forum access using Gitcoin Passport
# version: 0.0.1
# authors: Spect
# url: https://passport.gitcoin.co/
# required_version: 2.7.0

enabled_site_setting :gitcoin_passport_enabled

register_asset "stylesheets/create-account-feedback-message.scss"
register_asset "stylesheets/passport-score-value.scss"


require_relative "app/validators/ethaddress_validator.rb"
require_relative "app/validators/date_validator.rb"

after_initialize do
  module ::DiscourseGitcoinPassport
    PLUGIN_NAME = "discourse-gitcoin-passport"


    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseGitcoinPassport
    end

    class Error < StandardError
    end
  end

  require_relative "app/controllers/passport_controller.rb"
  require_relative "lib/gitcoin_passport_module/passport.rb"
  require_relative "lib/gitcoin_passport_module/access_without_passport.rb"
  require_relative "app/models/user_passport_score.rb"
  require_relative "app/models/category_passport_score.rb"


  DiscourseGitcoinPassport::Engine.routes.draw do
    get "/score" => "passport#score"
    put "/saveUserScore" => "passport#saveUserScore"
    put "/saveCategoryScore" => "passport#saveCategoryScore"
    put "/refreshPassportScore" => "passport#refreshPassportScore"
  end

  Discourse::Application.routes.append { mount ::DiscourseGitcoinPassport::Engine, at: "/passport" }

  reloadable_patch do |plugin|
    User.class_eval { has_many :user_passport_scores, dependent: :destroy }
    Category.class_eval { has_many :category_passport_scores, dependent: :destroy }

    UsersController.class_eval do
      def create
        if SiteSetting.gitcoin_passport_enabled && SiteSetting.gitcoin_passport_scorer_id
          puts "DiscourseGitcoinPassport::UsersController.create"
          puts current_user.inspect
          sesh_hash = session.to_hash
          ethaddress = sesh_hash['authentication']['extra_data']['uid'] if sesh_hash['authentication'] && sesh_hash['authentication']['extra_data']
          puts "ethaddress: #{ethaddress}"
          if (!ethaddress)
            render json: { status: 403, error: "You must connect your wallet to create an account" }
            return
          end

          score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
          required_score_to_create_account = SiteSetting.gitcoin_passport_forum_level_score_to_create_account.to_f || 0

          if score.to_i < required_score_to_create_account
            render json: { status: 403, reason: 'GitcoinPassportLessThanRequiredScore', error: "You must have a score of #{required_score_to_create_account} to create an account. Currently, you have a score of #{score}." }
            return
          else
            super
          end
        else
          super
        end
      end
    end

    SiweAuthenticator.class_eval do
      def after_authenticate(auth_token, existing_account: nil)
        puts "after_authenticate child"
        if DiscourseGitcoinPassport::AccessWithoutPassport.expired?
          puts "expired_due_to_no_gitcoin_passport_in_auth_token"
          minimum_required_score = SiteSetting.gitcoin_passport_forum_level_score_to_create_account.to_f

          ethaddress = auth_token[:uid]
          puts 'ethaddress is: ' + ethaddress
          if (ethaddress == nil)
            return(
              Auth::Result.new.tap do |auth_result|
                auth_result.failed = true
                auth_result.failed_reason = I18n.t("gitcoin_passport.has_not_connected_wallet")
              end
            )
          end
          score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
          puts 'Score inside after_authenticate is: ' + score.to_s

          if score.to_f < minimum_required_score
            return(
              Auth::Result.new.tap do |auth_result|
                auth_result.failed = true
                failed_reason = I18n.t("gitcoin_passport.doesnt_meet_requirement", score: score, required_score: minimum_required_score)
                auth_result.failed_reason = failed_reason
              end
            )
          end

        end
        super
      end
    end

    SessionController.class_eval do
      alias_method :existing_login_error_check, :login_error_check
      def login_error_check(user)
        puts "create child"
        puts user.inspect
        if DiscourseGitcoinPassport::AccessWithoutPassport.expired?
          puts "expired_due_to_no_gitcoin_passport_in_auth_token"
          minimum_required_score = SiteSetting.gitcoin_passport_forum_level_score_to_create_account.to_f
          puts 'associate_accounts is: ' + user[:associate_accounts].inspect
          siwe_account = @user.associated_accounts.find { |account| account[:name] == "siwe" }
          puts siwe_account.inspect
          ethaddress = siwe_account[:description]

          if (ethaddress == nil)
            return(
              { error:  I18n.t("gitcoin_passport.has_not_connected_wallet"), reason: "forbidden" }
            )
          end
          score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
          puts 'Score inside create is: ' + score.to_s

          if score.to_f < minimum_required_score
              return(
                { error:  I18n.t("gitcoin_passport.doesnt_meet_requirement"), reason: "forbidden" }
              )
          end
        end
        existing_login_error_check(user)
      end
    end

    TopicGuardian.class_eval do
      alias_method :existing_can_create_post_on_topic?, :can_create_post_on_topic?
      alias_method :existing_can_create_topic_on_category?, :can_create_topic_on_category?

      def ethaddress
        puts "ethaddress child"
        siwe_account = @user.associated_accounts.find { |account| account[:name] == "siwe" }
        puts siwe_account.inspect
        siwe_account[:description]
      end


      def can_create_post_on_topic?(topic)
        puts "can_create_post_on_topic child"
        if DiscourseGitcoinPassport::AccessWithoutPassport.expired?
          puts "expired_due_to_no_gitcoin_passport_associated_accounts"
          if !DiscourseGitcoinPassport::Passport.has_minimimum_required_score?(ethaddress(), @user.id, topic.category_id, UserAction.types[:reply])
            return false
          end
        end
        existing_can_create_post_on_topic?(topic)
      end

      def can_create_topic_on_category?(category)
        puts "can_create_topic_on_category child"
        puts @user.inspect

        if DiscourseGitcoinPassport::AccessWithoutPassport.expired?
          puts "expired_due_to_no_gitcoin_passport_associated_accounts"
          if !DiscourseGitcoinPassport::Passport.has_minimimum_required_score?(ethaddress(), @user.id, category.id, UserAction.types[:new_topic])
            return false
          end
        end
        existing_can_create_topic_on_category?(category)
      end
    end
  end

  add_to_serializer(
    :current_user,
    :passport_score,
  ) do
    object.passport_score
  end

  add_to_serializer(
    :admin_detailed_user,
    :min_score_to_post,
  ) do
    UserPassportScore
      .where(user_id: object.id, user_action_type: UserAction.types[:reply]).exists? ? UserPassportScore.where(user_id: object.id, user_action_type: UserAction.types[:reply]).first.required_score : 0
  end

  add_to_serializer(
    :admin_detailed_user,
    :min_score_to_create_topic,
  ) do
    UserPassportScore
      .where(user_id: object.id, user_action_type: UserAction.types[:new_topic]).exists? ? UserPassportScore.where(user_id: object.id, user_action_type: UserAction.types[:new_topic]).first.required_score : 0
  end

  add_to_serializer(
    :category,
    :min_score_to_post,
  ) do
    CategoryPassportScore
      .where(category_id: object.id, user_action_type: UserAction.types[:reply]).exists? ? CategoryPassportScore.where(category_id: object.id, user_action_type: UserAction.types[:reply]).first.required_score : 0
  end

  add_to_serializer(
    :category,
    :min_score_to_create_topic,
  ) do
    CategoryPassportScore
      .where(category_id: object.id, user_action_type: UserAction.types[:new_topic]).exists? ? CategoryPassportScore.where(category_id: object.id, user_action_type: UserAction.types[:new_topic]).first.required_score : 0
  end
end
