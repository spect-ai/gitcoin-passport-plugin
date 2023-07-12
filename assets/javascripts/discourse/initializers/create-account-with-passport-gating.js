import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "I18n";
import { getOwner } from "@ember/application";

export function initializeCreateAccountWithGitcoinPassport(api) {
  api.modifyClass("controller:create-account", {
    performAccountCreation() {
      const gitcoinPassport = getOwner(this).lookup("service:gitcoin-passport");
      const siteSettings = getOwner(this).lookup("service:site-settings");

      if (
        gitcoinPassport.score === undefined &&
        !gitcoinPassport.fetchingScore &&
        gitcoinPassport.errorWhileFetchingScore === undefined
      ) {
        return gitcoinPassport.fetchPassportScore().then(() => {
          this.performAccountCreation();
        });
      } else {
        if (
          gitcoinPassport.errorWhileFetchingScore ||
          gitcoinPassport.score === undefined
        ) {
          console.log("error while fetching score");
          this.flash(
            I18n.t("gitcoin_passport.error.while_fetching_score"),
            "error"
          );
        } else {
          const minScoreRequired = parseFloat(
            siteSettings.gitcoin_passport_forum_level_score_to_create_account
          );
          if (gitcoinPassport.score < minScoreRequired) {
            this.flash(
              I18n.t("gitcoin_passport.error.doesnt_meet_requirement", {
                required_score: minScoreRequired,
                score: gitcoinPassport.score,
              }),
              "error"
            );
          } else {
            this._super(...arguments);
          }
        }
      }
    },

    actions: {
      createAccount() {
        const gitcoinPassport = getOwner(this).lookup(
          "service:gitcoin-passport"
        );
        gitcoinPassport.reset();
        this._super(...arguments);
      },
    },
  });
}

export default {
  name: "discourse-gitcoin-passport",
  initialize() {
    withPluginApi("0.8.7", initializeCreateAccountWithGitcoinPassport);
  },
};
