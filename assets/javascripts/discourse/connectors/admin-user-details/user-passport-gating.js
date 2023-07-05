import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { extractError, popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";

export default class UserPassportGating extends Component {
  @service siteSettings;
  get isPassportEnabled() {
    return this.siteSettings.passport_enabled;
  }

  get username() {
    const { username } = this.args.outletArgs.model;
    return username;
  }

  get userId() {
    const { id } = this.args.outletArgs.model;
    return id;
  }

  get minScoreToPost() {
    console.log(this.args.outletArgs.model);
    return this.args.outletArgs.model.min_score_to_post || 0;
  }

  get minScoreToCreateTopic() {
    return this.args.outletArgs.model.min_score_to_create_topic || 0;
  }

  @action
  saveMinimumScoreToCreatePost(newScore) {
    let userId = this.userId;
    const oldScore = this.minScoreToPost;
    this.args.outletArgs.model.set("minScoreToPost", newScore);

    ajax({
      url: "/passport/saveUserScore",
      type: "PUT",
      data: {
        user_id: userId,
        action_id: 5,
        score: newScore,
      },
    })
      .catch((e) => {
        this.args.outletArgs.model.set("minScoreToPost", oldScore);
        popupAjaxError(e);
      })
      .finally(() => {
        this.args.outletArgs.model.toggleProperty(
          "editingMinimumScoreToCreatePost"
        );
      });
  }

  @action
  saveMinimumScoreToCreateTopic(newScore) {
    let userId = this.userId;
    const oldScore = this.minScoreToCreateTopic;
    this.args.outletArgs.model.set("minScoreToCreateTopic", newScore);
    ajax({
      url: "/passport/saveUserScore",
      type: "PUT",
      data: {
        user_id: userId,
        action_id: 4,
        score: newScore,
      },
    })
      .catch((e) => {
        this.args.outletArgs.model.set("minScoreToCreateTopic", oldScore);
        popupAjaxError(e);
      })
      .finally(() => {
        this.args.outletArgs.model.toggleProperty(
          "editingMinimumScoreToCreateTopic"
        );
      });
  }
}
