import Component from "@glimmer/component";
import { tagName } from "@ember-decorators/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { computed } from "@ember/object";

@tagName("")
export default class PassportGating extends Component {
  @service gitcoinPassport;
  @service siteSettings;

  @action
  checkPassport() {
    this.gitcoinPassport.checkPassport();
  }

  @computed("gitcoinPassport.score")
  get passportScore() {
    return this.gitcoinPassport.passportScore();
  }

  @computed("gitcoinPassport.satisfiesRequirements")
  get satisfiesScoreRequirement() {
    console.log(this.gitcoinPassport.satisfiesScoreRequirements());
    return this.gitcoinPassport.satisfiesScoreRequirements();
  }

  @computed("gitcoinPassport.hasConnectedWallet")
  get hasConnectedWallet() {
    return this.gitcoinPassport.hasConnectedWallet();
  }
}
