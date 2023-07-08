# frozen_string_literal: true

# name: discourse-gitcoin-passport
# about: A discourse plugin to enable users to manage forum access using Gitcoin Passport
# version: 0.0.1
# authors: Spect
# url: https://passport.gitcoin.co/
# required_version: 2.7.0

enabled_site_setting :gitcoin_passport_enabled

register_asset "stylesheets/create-account-feedback-message.scss"

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
  require_relative "app/controllers/users_controller.rb"
  require_relative "lib/gitcoin_passport_module/passport.rb"
  require_relative "app/models/user_passport_score.rb"
  require_relative "app/models/category_passport_score.rb"


  DiscourseGitcoinPassport::Engine.routes.draw do
    get "/score" => "passport#score"
    put "/saveUserScore" => "passport#saveUserScore"
    put "/saveCategoryScore" => "passport#saveCategoryScore"
  end

  Discourse::Application.routes.append { mount ::DiscourseGitcoinPassport::Engine, at: "/passport" }

  reloadable_patch do |plugin|
    UsersController.prepend DiscourseGitcoinPassport::UsersController
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


  reloadable_patch do
    TopicGuardian.class_eval do
      alias_method :existing_can_create_post_on_topic?, :can_create_post_on_topic?
      alias_method :existing_can_create_topic_on_category?, :can_create_topic_on_category?

      def can_create_post_on_topic?(topic)
        puts "can_create_post_on_topic child"
        if SiteSetting.gitcoin_passport_enabled
          minimum_required_score = SiteSetting.gitcoin_passport_forum_level_score_to_post.to_f
          category_passport_score = CategoryPassportScore.where(category_id: topic.category_id, user_action_type: UserAction.types[:reply]).first
          puts category_passport_score
          if category_passport_score
            minimum_required_score = category_passport_score.required_score
          end
          user_passport_score = UserPassportScore.where(user_id: @user.id, user_action_type: UserAction.types[:reply]).first
          if user_passport_score
            minimum_required_score = user_passport_score.required_score
          end
          puts minimum_required_score
          puts JSON.generate(@user.associated_accounts)
          associated_siwe = @user.associated_accounts.find { |account| account[:name] == 'siwe' }
          ethaddress = associated_siwe[:description]
          score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
          puts score
          if score.to_f < minimum_required_score
            return false
          end
        end
        existing_can_create_post_on_topic?(topic)
      end

      def can_create_topic_on_category?(category)
        puts "can_create_topic_on_category child"
        if SiteSetting.gitcoin_passport_enabled
          minimum_required_score = SiteSetting.gitcoin_passport_forum_level_score_to_create_new_topic.to_f
          category_passport_score = CategoryPassportScore.where(category_id: category.id, user_action_type: UserAction.types[:new_topic]).first
          if category_passport_score and category_passport_score.required_score and category_passport_score.required_score > 0
            minimum_required_score = category_passport_score.required_score
          end
          user_passport_score = UserPassportScore.where(user_id: @user.id, user_action_type: UserAction.types[:new_topic]).first
          if user_passport_score and user_passport_score.required_score and user_passport_score.required_score > 0
            minimum_required_score = user_passport_score.required_score
          end
          puts 'minimum_required_score is: ' + minimum_required_score.to_s
          puts JSON.generate(@user.associated_accounts)
          associated_siwe = @user.associated_accounts.find { |account| account[:name] == 'siwe' }
          ethaddress = associated_siwe[:description]
          score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
          puts score
          if score.to_f < minimum_required_score
            return false
          end
        end
        existing_can_create_topic_on_category?(category)
      end
    end
  end
end
