///|
/// Fixed groups must be determined without calibration outcomes.
pub struct GroupScores {
  groups : Map[String, Scores]
  names : Array[String]
}

///|
/// Keeps small groups separate; never silently pools an unseen group.
pub fn grouped_scores(
  values : Array[Double],
  groups : Array[String],
) -> GroupScores raise ConformalError {
  validate_values(values, "grouped scores")
  same_length(values.length(), groups.length())
  let buckets : Map[String, Array[Double]] = Map([])
  for i in 0..<groups.length() {
    let key = groups[i]
    if key.length() == 0 || key.length() > 256 {
      raise Invalid("group names must contain 1..256 code units")
    }
    match buckets.get(key) {
      Some(bucket) => bucket.push(values[i])
      None => buckets.set(key, [values[i]])
    }
    if buckets.length() > 10000 {
      raise ResourceLimit("at most 10000 groups")
    }
  }
  let result : Map[String, Scores] = Map([])
  let names = []
  for name, bucket in buckets {
    result.set(name, Scores::new(bucket))
    names.push(name)
  }
  names.sort()
  { groups: result, names, }
}

///|
/// Sorted defensive copy, independent of hash iteration order.
pub fn GroupScores::names(self : GroupScores) -> Array[String] {
  self.names.copy()
}

///|
pub fn GroupScores::get(
  self : GroupScores,
  group : String,
) -> Scores raise ConformalError {
  match self.groups.get(group) {
    Some(scores) => scores
    None => raise UnknownGroup(group)
  }
}

///|
/// Each group's own n is used for the finite-sample correction.
pub fn GroupScores::thresholds(
  self : GroupScores,
  alpha : Double,
) -> Array[(String, Double)] raise ConformalError {
  validate_alpha(alpha)
  self.names.map(name => (name, self.get(name).threshold(alpha)))
}

///|
pub fn predict_grouped_absolute(
  scores : GroupScores,
  prediction : Array[Double],
  groups : Array[String],
  alpha : Double,
) -> Array[Interval] raise ConformalError {
  validate_values(prediction, "prediction")
  same_length(prediction.length(), groups.length())
  validate_alpha(alpha)
  let result = []
  for i in 0..<prediction.length() {
    let group = scores.get(groups[i])
    if group.sorted[0] < 0.0 {
      raise Invalid("absolute group scores must be nonnegative")
    }
    result.push(checked_interval(prediction[i], group.threshold(alpha)))
  }
  result
}
