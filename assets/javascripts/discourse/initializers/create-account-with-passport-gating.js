import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-gitcoin-passport",
  initialize(container) {
    withPluginApi("0.8.7", (api) => {
      api.modifyClass("controller:create-account", {
        actions: {
          createAccount() {
            console.log("createAccount123");
            const res = true;

            console.log("createAccountAfterCheckingPassport");
            this.gitcoinPassport = api.container.lookup(
              "service:gitcoin-passport"
            );
            this.siteSettings = api.container.lookup("service:site-settings");
            const { score, satisfiesRequirements } =
              this.gitcoinPassport.checkPassportScoreScore(
                this.siteSettings
                  .gitcoin_passport_forum_level_score_to_create_account
              );
            console.log({ score, satisfiesRequirements });

            this._super(...arguments);
          },
        },
      });
    });
  },
};
