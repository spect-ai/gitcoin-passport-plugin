module ::DiscourseGitcoinPassport

  module UsersController

    def create
      puts "UsersController"
      sesh_hash = session.to_hash
      ethaddress = sesh_hash['authentication']['extra_data']['uid']

      render json: { status: 403, error: "You must connect your wallet to create an account" } if !ethaddress

      score = DiscourseGitcoinPassport::Passport.score(ethaddress, SiteSetting.gitcoin_passport_scorer_id)
      required_score_to_create_account = SiteSetting.gitcoin_passport_forum_level_score_to_create_account.to_f
      puts required_score_to_create_account
      puts score
      if score.to_i < required_score_to_create_account
        render json: { status: 403, reason: 'GitcoinPassportLessThanRequiredScore', error: "You must have a score of #{required_score_to_create_account} to create an account. Currently, you have a score of #{score}." }
      else
        super
      end
    end
  end

end
