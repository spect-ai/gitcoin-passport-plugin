import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-gitcoin-passport",
  initialize(container) {
    this.gitcoinPassport = container.lookup("service:gitcoin-passport");
    this.siteSettings = container.lookup("service:site-settings");
    withPluginApi("0.8.7", (api) => {
      api.modifyClass("controller:create-account", {
        actions: {
          createAccount: () => {
            this.gitcoinPassport
              .checkPassportScoreScore(
                this.siteSettings
                  .gitcoin_passport_forum_level_score_to_create_account
              )
              .then((result) => {
                if (result.satisfiesRequirements) {
                  this._super();
                }
              });
          },
        },
      });
    });
  },
};
