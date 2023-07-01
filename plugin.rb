# frozen_string_literal: true

# name: discourse-gitcoin-passport
# about: TODO
# version: 0.0.1
# authors: Spect
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_gitcoin_passport_enabled

module ::DiscourseGitcoinPassport
  PLUGIN_NAME = "discourse-gitcoin-passport"
end

require_relative "lib/gitcoin_passport_module/engine"

after_initialize do
  # Code which should run after Rails has finished booting
end
