///|
fn validate_bounds(
  lower : Array[Double],
  upper : Array[Double],
) -> Unit raise ConformalError {
  validate_values(lower, "lower predictions")
  validate_values(upper, "upper predictions")
  same_length(lower.length(), upper.length())
  for i in 0..<lower.length() {
    if lower[i] > upper[i] {
      raise Invalid("base quantile predictions cross")
    }
  }
}

///|
/// Signed CQR score max(lower-y, y-upper); negative scores must not be clipped.
pub fn cqr_scores(
  truth : Array[Double],
  lower : Array[Double],
  upper : Array[Double],
) -> Scores raise ConformalError {
  validate_values(truth, "truth")
  validate_bounds(lower, upper)
  same_length(truth.length(), lower.length())
  let out = []
  for i in 0..<truth.length() {
    let a = lower[i] - truth[i]
    let b = truth[i] - upper[i]
    let score = if a > b { a } else { b }
    if !finite(a) || !finite(b) {
      raise Invalid("CQR residual overflow")
    }
    out.push(score)
  }
  Scores::new(out)
}

///|
pub fn predict_cqr(
  scores : Scores,
  lower : Array[Double],
  upper : Array[Double],
  alpha : Double,
) -> Array[Interval] raise ConformalError {
  validate_bounds(lower, upper)
  let q = scores.threshold(alpha)
  let out = []
  for i in 0..<lower.length() {
    if q.is_pos_inf() {
      out.push({ lower: @double.neg_infinity, upper: @double.infinity, })
    } else {
      let lo = lower[i] - q
      let hi = upper[i] + q
      if !finite(lo) || !finite(hi) {
        raise Invalid("CQR endpoint overflow")
      }
      out.push({ lower: lo, upper: hi, })
    }
  }
  out
}
