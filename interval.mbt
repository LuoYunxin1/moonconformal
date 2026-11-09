///|
/// A prediction set on the real line. lower > upper is a valid empty set.
pub(all) struct Interval {
  lower : Double
  upper : Double
}

///|
pub fn Interval::contains(self : Interval, value : Double) -> Bool {
  finite(value) && self.lower <= value && value <= self.upper
}

///|
pub fn Interval::is_empty(self : Interval) -> Bool {
  self.lower > self.upper
}

///|
pub fn Interval::width(self : Interval) -> Double {
  if self.is_empty() {
    0.0
  } else {
    self.upper - self.lower
  }
}

///|
pub fn Interval::intersect(self : Interval, other : Interval) -> Interval {
  {
    lower: if self.lower > other.lower {
      self.lower
    } else {
      other.lower
    },
    upper: if self.upper < other.upper {
      self.upper
    } else {
      other.upper
    },
  }
}

///|
fn same_length(a : Int32, b : Int32) -> Unit raise ConformalError {
  if a != b {
    raise Invalid("array lengths differ")
  }
}

///|
fn checked_interval(
  center : Double,
  radius : Double,
) -> Interval raise ConformalError {
  if !finite(center) {
    raise Invalid("prediction must be finite")
  }
  if radius.is_pos_inf() {
    return { lower: @double.neg_infinity, upper: @double.infinity, }
  }
  let lower = center - radius
  let upper = center + radius
  if !finite(lower) || !finite(upper) {
    raise Invalid("finite interval endpoint overflow")
  }
  { lower, upper, }
}

///|
/// Absolute-residual split conformal calibration, independent of model training.
pub fn absolute_scores(
  truth : Array[Double],
  prediction : Array[Double],
) -> Scores raise ConformalError {
  validate_values(truth, "truth")
  validate_values(prediction, "prediction")
  same_length(truth.length(), prediction.length())
  let residuals = []
  for i in 0..<truth.length() {
    let residual = (truth[i] - prediction[i]).abs()
    if !finite(residual) {
      raise Invalid("residual overflow")
    }
    residuals.push(residual)
  }
  Scores::new(residuals)
}

///|
pub fn predict_absolute(
  scores : Scores,
  prediction : Array[Double],
  alpha : Double,
) -> Array[Interval] raise ConformalError {
  validate_values(prediction, "prediction")
  let radius = scores.threshold(alpha)
  if radius < 0.0 {
    raise Invalid("absolute residual scores must be nonnegative")
  }
  prediction.map(p => checked_interval(p, radius))
}
