import Component from "@ember/component";
import { action, didInsertElement } from "@ember/object";
import { inject as service } from "@ember/service";
import I18n from "I18n";
import discourseComputed from "discourse-common/utils/decorators";

export default class PassportGatingBanner extends Component {
  @service siteSettings;
  @service currentUser;

  passportGatingMessageHiddenByUser = false;
  passportGatingActive =
    this.siteSettings.gitcoin_passport_enabled &&
    new Date(
      this.siteSettings.gitcoin_passport_last_date_to_connect_wallet_for_existing_users
    ) < new Date();
  passportGatingEnabled = this.siteSettings.gitcoin_passport_enabled;
  message = null;
  linkTo = null;
  linkText = null;
  showBanner = false;
  showScores = false;
  showActivationDate = false;
  canDismiss = false;

  didInsertElement() {
    console.log({
      passportGatingActive: this.passportGatingActive,
      currentUser: this.currentUser,
    });
    if (!this.passportGatingActive && !this.currentUser?.ethaddress) {
      this.set(
        "message",
        I18n.t("gitcoin_passport.banner.inactive_gating_not_connected_wallet")
      );
      this.set("linkTo", "linkAccount");
      this.set("linkText", "gitcoin_passport.banner.link_to_connect_wallet");
      this.set("showBanner", true);
      this.set("showScores", false);
      this.set("showActivationDate", true);
      this.set("canDismiss", true);
      return;
    } else if (this.passportGatingActive && !this.currentUser?.ethaddress) {
      this.set(
        "message",
        I18n.t("gitcoin_passport.banner.active_gating_not_connected_wallet")
      );
      this.set("linkTo", "linkAccount");
      this.set("linkText", "gitcoin_passport.banner.link_to_connect_wallet");
      this.set("showBanner", true);
      this.set("showScores", false);
      this.set("showActivationDate", false);
      this.set("canDismiss", false);
      return;
    } else if (!this.passportGatingActive && this.currentUser?.ethaddress) {
      const minimumScoreRequired =
        this.siteSettings.gitcoin_passport_forum_level_score_to_create_account;
      const score = this.currentUser.passport_score;
      if (!score || score < minimumScoreRequired) {
        this.set(
          "message",
          I18n.t("gitcoin_passport.banner.inactive_gating_low_score")
        );
        this.set("linkTo", "goToPassport");
        this.set("linkText", "gitcoin_passport.banner.link_to_passport");
        this.set("showBanner", true);
        this.set("showScores", true);
        this.set("showActivationDate", true);
        this.set("canDismiss", false);
        return;
      }
    } else if (this.passportGatingActive && this.currentUser?.ethaddress) {
      const minimumScoreRequired =
        this.siteSettings.gitcoin_passport_forum_level_score_to_create_account;
      const score = this.currentUser.passport_score;
      if (!score || score < minimumScoreRequired) {
        this.set(
          "message",
          I18n.t("gitcoin_passport.banner.active_gating_low_score")
        );
        this.set("linkTo", "goToPassport");
        this.set("linkText", "gitcoin_passport.banner.link_to_passport");
        this.set("showBanner", true);
        this.set("showScores", true);
        this.set("showActivationDate", false);
        this.set("canDismiss", false);
      }
      return;
    }
    this.set("showBanner", false);
    this.set("showScores", false);
    this.set("showActivationDate", false);
    this.set("canDismiss", false);
    this.set("message", null);
    this.set("linkTo", null);
    this.set("linkText", null);
  }

  @discourseComputed("canDismiss")
  canDismissBanner() {
    return this.canDismiss;
  }

  @discourseComputed("showActivationDate")
  showActivationDateInBanner() {
    return this.showActivationDate;
  }

  @discourseComputed("showScores")
  userScore() {
    console.log({ score: this.score });
    return this.score || 0;
  }

  @discourseComputed("passportGatingMessageHiddenByUser", "showBanner")
  showPassportGatingMessage() {
    console.log({ t: this.passportGatingMessageHiddenByUser });
    if (
      !this.currentUser ||
      !this.passportGatingEnabled ||
      this.passportGatingMessageHiddenByUser
    ) {
      return false;
    }
    console.log({
      showBanner: this.showBanner,
      passportGatingMessageHiddenByUser: this.passportGatingMessageHiddenByUser,
    });
    return this.showBanner && !this.passportGatingMessageHiddenByUser;
  }

  @discourseComputed("message")
  bannerMessage() {
    return this.message;
  }

  @discourseComputed("linkTo")
  redirectLink() {
    return this.linkTo;
  }

  @discourseComputed("linkText")
  redirectLinkText() {
    return this.linkText;
  }

  @action
  dismiss() {
    console.log("dismiss");
    this.set("passportGatingMessageHiddenByUser", true);
  }

  @action
  goToPassport() {
    window.location.href = "https://gitcoin.co/onboard";
  }

  @action
  linkAccount() {
    window.location.href = "/discourse-siwe/auth";
  }
}
