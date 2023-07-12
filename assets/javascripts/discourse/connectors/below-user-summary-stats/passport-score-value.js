import { tagName } from "@ember-decorators/component";
import Component from "@ember/component";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";

@tagName("passport-score-value")
export default class PassportScoreValue extends Component {
  refreshingScore = false;

  @discourseComputed("outletArgs.user.passport_score")
  score() {
    console.log("refreshing");
    return this.outletArgs.user.passport_score;
  }

  @action
  refreshScore() {
    this.set("refreshingScore", true);
    ajax({
      url: "/passport/refreshPassportScore",
      type: "PUT",
    })
      .then((result) => {
        console.log({ rest: result });
        console.log({ outletArgs: this.outletArgs.user });
        this.outletArgs.user.set("passport_score", result.score);
      })
      .catch((e) => {
        popupAjaxError(e);
      })
      .finally(() => {
        this.set("refreshingScore", false);
      });
  }
}
