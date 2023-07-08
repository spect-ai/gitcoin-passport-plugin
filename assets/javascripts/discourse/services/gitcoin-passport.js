import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";

export default class GitcoinPassportService extends Service {
  @tracked score = 0;
  @tracked satisfiesRequirements = null;
  @tracked authenticated = null;

  checkPassportScoreScore(minimumScoreRequired) {
    return ajax("/passport/score")
      .then((result) => {
        console.log({ rest: result });
        const score = parseFloat(result.score);
        this.score = score;

        if (minimumScoreRequired && score >= parseFloat(minimumScoreRequired)) {
          this.satisfiesRequirements = true;
        } else if (minimumScoreRequired && score < minimumScoreRequired) {
          this.satisfiesRequirements = false;
        }
        this.authenticated = true;
        return {
          score: score,
          satisfiesRequirements: this.satisfiesRequirements,
        };
      })
      .catch((e) => {
        console.log(e);
        if (e.errorThrown === "Forbidden") {
          console.log("Forbidden");
          this.authenticated = false;
        }

        return {
          score: 0,
          satisfiesRequirements: false,
        };
      });
  }

  satisfiesScoreRequirements() {
    return this.satisfiesRequirements;
  }

  passportScore() {
    return this.score;
  }

  hasConnectedWallet() {
    return this.authenticated;
  }
}
