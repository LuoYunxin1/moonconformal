///|
pub(all) enum SetRule {
  Lac
  Aps
}

///|
pub struct ClassCalibrator {
  scores : Scores
  classes : Int32
  rule : SetRule
}

///|
fn validate_probability(row : Array[Double]) -> Unit raise ConformalError {
  validate_values(row, "probability row")
  if row.length() < 2 || row.length() > 1024 {
    raise Invalid("class count must be in 2..1024")
  }
  let mut total = 0.0
  for value in row {
    if value < 0.0 || value > 1.0 {
      raise Invalid("probability must be in [0,1]")
    }
    total = total + value
  }
  if (total - 1.0).abs() > 1.0e-10 {
    raise Invalid("probability row must sum to one within 1e-10")
  }
}

///|
/// Returns one score per candidate label, in label-index order.
pub fn label_scores(
  row : Array[Double],
  rule : SetRule,
) -> Array[Double] raise ConformalError {
  validate_probability(row)
  match rule {
    Lac => row.map(p => 1.0 - p)
    Aps => cumulative_scores(row, 0.0, row.length())
  }
}

///|
fn validate_probability_batch(
  rows : Array[Array[Double]],
  classes : Int32,
) -> Unit raise ConformalError {
  if rows.is_empty() || rows.length() > 100000 {
    raise Invalid("probability batch size must be in 1..100000")
  }
  if classes < 2 || classes > 1024 || rows.length() > 2000000 / classes {
    raise ResourceLimit(
      "probability matrix exceeds 2000000 cells or class limit",
    )
  }
  for row in rows {
    same_length(row.length(), classes)
    validate_probability(row)
  }
}

///|
pub fn calibrate_classifier(
  rows : Array[Array[Double]],
  labels : Array[Int32],
  rule : SetRule,
) -> ClassCalibrator raise ConformalError {
  if rows.is_empty() {
    raise Invalid("calibration probability matrix is empty")
  }
  let classes = rows[0].length()
  validate_probability_batch(rows, classes)
  same_length(rows.length(), labels.length())
  let values = []
  for i in 0..<rows.length() {
    if labels[i] < 0 || labels[i] >= classes {
      raise Invalid("true label index is outside probability row")
    }
    values.push(label_scores(rows[i], rule)[labels[i]])
  }
  { scores: Scores::new(values), classes, rule, }
}

///|
pub fn ClassCalibrator::count(self : ClassCalibrator) -> Int32 {
  self.scores.count()
}

///|
pub fn ClassCalibrator::class_count(self : ClassCalibrator) -> Int32 {
  self.classes
}

///|
pub fn ClassCalibrator::predict(
  self : ClassCalibrator,
  rows : Array[Array[Double]],
  alpha : Double,
) -> Array[Array[Int32]] raise ConformalError {
  validate_probability_batch(rows, self.classes)
  let threshold = self.scores.threshold(alpha)
  let sets = []
  for row in rows {
    let scores = label_scores(row, self.rule)
    let selected = []
    for label in 0..<self.classes {
      if scores[label] <= threshold {
        selected.push(label)
      }
    }
    sets.push(selected)
  }
  sets
}
