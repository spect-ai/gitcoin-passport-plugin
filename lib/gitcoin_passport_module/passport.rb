# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

class DiscourseGitcoinPassport::Passport

  def self.score(user_address, scorer_id)
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
end
