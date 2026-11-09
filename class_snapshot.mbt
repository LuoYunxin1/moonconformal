///|
/// The rule and class count are necessary to reproduce prediction sets.
pub fn ClassCalibrator::to_snapshot(self : ClassCalibrator) -> String {
  let (rule, penalty, after) = match self.rule {
    Lac => ("lac", 0.0, 0)
    Aps => ("aps", 0.0, 0)
    Raps(penalty, after) => ("raps", penalty, after)
  }
  Json::object(
    Map([
      ("schema", Json::number(1.0)),
      ("kind", Json::string("classifier")),
      ("classes", Json::number(self.classes.to_double())),
      ("rule", Json::string(rule)),
      ("penalty", Json::number(penalty)),
      ("after", Json::number(after.to_double())),
      ("scores", Json::array(self.scores.sorted.map(x => Json::number(x)))),
    ]),
  ).stringify()
}

///|
fn snapshot_integer(
  value : Json,
  low : Int32,
  high : Int32,
) -> Int32 raise ConformalError {
  let number = snapshot_number(value)
  if number < low.to_double() ||
    number > high.to_double() ||
    number.floor() != number {
    raise Invalid("snapshot integer outside range")
  }
  number.to_int()
}

///|
/// Restores only validated states; it cannot certify how calibration data was obtained.
pub fn ClassCalibrator::from_snapshot(
  text : String,
) -> ClassCalibrator raise ConformalError {
  let fields = snapshot_object(snapshot_parse(text), [
    "schema", "kind", "classes", "rule", "penalty", "after", "scores",
  ])
  snapshot_version(fields, "classifier")
  let classes = snapshot_integer(snapshot_field(fields, "classes"), 2, 1024)
  let penalty = snapshot_number(snapshot_field(fields, "penalty"))
  let after = snapshot_integer(snapshot_field(fields, "after"), 0, classes)
  let rule = match snapshot_field(fields, "rule") {
    String("lac") => {
      if penalty != 0.0 || after != 0 {
        raise Invalid("LAC snapshot has RAPS parameters")
      }
      Lac
    }
    String("aps") => {
      if penalty != 0.0 || after != 0 {
        raise Invalid("APS snapshot has RAPS parameters")
      }
      Aps
    }
    String("raps") => {
      if penalty < 0.0 {
        raise Invalid("negative snapshot penalty")
      }
      Raps(penalty, after)
    }
    _ => raise Invalid("unknown snapshot classification rule")
  }
  let scores = snapshot_scores(snapshot_field(fields, "scores"))
  let maximum = match rule {
    Lac | Aps => 1.0 + 1.0e-10
    Raps(lambda, k) => 1.0 + 1.0e-10 + lambda * (classes - k).to_double()
  }
  if !finite(maximum) {
    raise Invalid("snapshot rule overflows at full rank")
  }
  for score in scores.sorted {
    if score < 0.0 || score > maximum {
      raise Invalid("snapshot score outside rule range")
    }
  }
  { scores, classes, rule, }
}
