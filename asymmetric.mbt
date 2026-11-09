///|
/// Separate tail calibration, using a union bound for the requested total error.
pub struct TailScores {
  low : Scores
  high : Scores
}

///|
pub fn tail_scores(
  truth : Array[Double],
  prediction : Array[Double],
) -> TailScores raise ConformalError {
  validate_values(truth, "truth")
  validate_values(prediction, "prediction")
  same_length(truth.length(), prediction.length())
  let low = []
  let high = []
  for i in 0..<truth.length() {
    let residual = truth[i] - prediction[i]
    if !finite(residual) {
      raise Invalid("tail residual overflow")
    }
    low.push(-residual)
    high.push(residual)
  }
  { low: Scores::new(low), high: Scores::new(high), }
}

///|
pub fn TailScores::count(self : TailScores) -> Int32 {
  self.low.count()
}

///|
/// low_fraction allocates total alpha to the lower-tail failure event.
pub fn predict_tails(
  scores : TailScores,
  prediction : Array[Double],
  alpha : Double,
  low_fraction : Double,
) -> Array[Interval] raise ConformalError {
  validate_alpha(alpha)
  validate_alpha(low_fraction)
  validate_values(prediction, "prediction")
  let low_alpha = alpha * low_fraction
  let high_alpha = alpha * (1.0 - low_fraction)
  let lo = scores.low.threshold(low_alpha)
  let hi = scores.high.threshold(high_alpha)
  let out = []
  for center in prediction {
    let lower = if lo.is_pos_inf() { @double.neg_infinity } else { center - lo }
    let upper = if hi.is_pos_inf() { @double.infinity } else { center + hi }
    if (!lo.is_pos_inf() && !finite(lower)) ||
      (!hi.is_pos_inf() && !finite(upper)) {
      raise Invalid("tail endpoint overflow")
    }
    out.push({ lower, upper, })
  }
  out
}
