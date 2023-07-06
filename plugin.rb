# frozen_string_literal: true

# name: discourse-gitcoin-passport
# about: TODO
# version: 0.0.1
# authors: Spect
# url: TODO
# required_version: 2.7.0

enabled_site_setting :gitcoin_passport_enabled


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
  require_relative "lib/gitcoin_passport_module/post_guardian_edits.rb"
  require_relative "lib/gitcoin_passport_module/topic_guardian_edits.rb"
  require_relative "app/models/user_passport_score.rb"
  require_relative "app/models/category_passport_score.rb"


  DiscourseGitcoinPassport::Engine.routes.draw do
    get "/score" => "passport#score"
    put "/saveUserScore" => "passport#saveUserScore"
    put "/saveCategoryScore" => "passport#saveCategoryScore"
  end

  Discourse::Application.routes.append { mount ::DiscourseGitcoinPassport::Engine, at: "/passport" }

  add_to_serializer(
    :admin_detailed_user,
    :min_score_to_post,
  ) do
    UserPassportScore
      .where(user_id: object.id, user_action_type: 5).exists? ? UserPassportScore.where(user_id: object.id, user_action_type: 5).first.required_score : 0
  end

  add_to_serializer(
    :admin_detailed_user,
    :min_score_to_create_topic,
  ) do
    UserPassportScore
      .where(user_id: object.id, user_action_type: 4).exists? ? UserPassportScore.where(user_id: object.id, user_action_type: 4).first.required_score : 0
  end

  add_to_serializer(
    :category,
    :min_score_to_post,
  ) do
    CategoryPassportScore
      .where(category_id: object.id, user_action_type: 5).exists? ? CategoryPassportScore.where(category_id: object.id, user_action_type: 5).first.required_score : 0
  end

  add_to_serializer(
    :category,
    :min_score_to_create_topic,
  ) do
    CategoryPassportScore
      .where(category_id: object.id, user_action_type: 4).exists? ? CategoryPassportScore.where(category_id: object.id, user_action_type: 4).first.required_score : 0
  end

end
