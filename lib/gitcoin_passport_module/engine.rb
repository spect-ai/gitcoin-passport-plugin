# frozen_string_literal: true

module ::GitcoinPassport
  PLUGIN_NAME ||= 'discourse-gitcoin-passport'

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseGitcoinPassport
    config.autoload_paths << File.join(config.root, "lib")
  end
end
