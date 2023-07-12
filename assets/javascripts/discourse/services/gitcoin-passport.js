import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";
import I18n from "I18n";

export default class GitcoinPassportService extends Service {
  @tracked fetchingScore = false;
  @tracked score = undefined;
  @tracked errorWhileFetchingScore = undefined;

  fetchPassportScore() {
    this.fetchingScore = true;
    return ajax("/passport/score")
      .then((result) => {
        console.log({ rest: result });
        const score = parseFloat(result.score);
        this.score = score;
      })
      .catch((e) => {
        this.errorWhileFetchingScore = e;
        this.score = undefined;
        this.fetchingScore = false;
      })
      .finally(() => {
        this.fetchingScore = false;
      });
  }

  reset() {
    this.score = undefined;
    this.errorWhileFetchingScore = undefined;
    this.fetchingScore = false;
  }
}
