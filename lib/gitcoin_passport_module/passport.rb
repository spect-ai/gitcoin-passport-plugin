# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

class DiscourseGitcoinPassport::Passport

  def self.score(user_address, scorer_id)
    puts 'ethaddress: ' + user_address.to_s
    url = URI("https://api.scorer.gitcoin.co/registry/submit-passport")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["x-api-key"] = SiteSetting.gitcoin_passport_api_key
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "address": user_address,
      "scorer_id": scorer_id
    })

    response = https.request(request)
    parsed_response = JSON.parse(response.read_body)

    parsed_response['score']
  end

  def self.minimum_required_score(user_id, category_id, action_type)
    minimum_required_score = 0

    # Forum level score
    if action_type == UserAction.types[:reply]
      minimum_required_score = SiteSetting.gitcoin_passport_forum_level_score_to_post.to_f
    else
      minimum_required_score = SiteSetting.gitcoin_passport_forum_level_score_to_create_new_topic.to_f
    end

    # Category level score overrides forum level score
    category_passport_score = CategoryPassportScore.where(category_id: category_id, user_action_type: action_type).first
    if category_passport_score and category_passport_score.required_score and category_passport_score.required_score > 0
      minimum_required_score = category_passport_score.required_score
    end

    # User level score overrides category level score and forum level score
    user_passport_score = UserPassportScore.where(user_id: user_id, user_action_type: action_type).first
    if user_passport_score and user_passport_score.required_score and user_passport_score.required_score > 0
      minimum_required_score = user_passport_score.required_score
    end

    minimum_required_score
  end

  def self.has_minimimum_required_score?(ethaddress, user_id, category_id, action_type)
    minimum_required_score = DiscourseGitcoinPassport::Passport.minimum_required_score(user_id, category_id, action_type)
    if (!ethaddress and minimum_required_score > 0)
      return false
    end
    if (minimum_required_score == 0) # No minimum score required
      return true
    end
    score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
    score.to_f >= minimum_required_score
  end

  def self.available_badges_to_claim(badges, passport_score)
    available_badges = []
    badges.each do |badge|
      if UserBadge.where(badge_id: bronze_badge.id).count
        if badge.badge_type.name == "Gold" and  passport_score.to_f >= SiteSetting.gitcoin_passport_required_to_get_unique_humanity_gold_badge.to_f
            available_badges.push(badge)
        elsif badge.badge_type.name == "Silver" and passport_score.to_f >= SiteSetting.gitcoin_passport_required_to_get_unique_humanity_silver_badge.to_f
            available_badges.push(badge)
        elsif badge.badge_type.name == "Bronze" and passport_score.to_f >= SiteSetting.gitcoin_passport_required_to_get_unique_humanity_bronze_badge.to_f
            available_badges.push(badge)
        end
      end
    end
    available_badges
  end

  def self.grant_badges(badges)
    available_badges.each do |badge|
      puts "Granting badge: #{badge.name}"
      BadgeGranter.grant(badge, current_user)
    end
  end

  def self.refresh_passport_score()
    puts current_user.inspect
    siwe_account = current_user.associated_accounts.find { |account| account[:name] == "siwe" }
      ethaddress = siwe_account[:description]

      raise Discourse::InvalidAccess.new("You must connect your wallet to view your score") if not ethaddress

      # save the latest passport score in the user table, this is mainly done for performance reasons.
      # We don't want to have to query the passport api every time we want to check if a person can create a topic or post
      score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
      user = User.where(id: current_user.id).first
      user.passport_score = score
      user.passport_score_last_update = DateTime.now
      user.save

      # check if the user has earned any badges and grant them
      badges = Badge.joins(:badge_type).joins(:badge_grouping).where(badge_groupings: {
        name: "Unique Humanity"
      })
      available_badges = DiscourseGitcoinPassport::Passport.available_badges_to_claim(badges, score)
      DiscourseGitcoinPassport::Passport.grant_badges(available_badges)
      return score
  end
end
