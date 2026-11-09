///|
fn validate_scales(
  scale : Array[Double],
  n : Int32,
) -> Unit raise ConformalError {
  validate_values(scale, "scale")
  same_length(scale.length(), n)
  for value in scale {
    if value <= 0.0 {
      raise Invalid("scales must be strictly positive")
    }
  }
}

///|
/// The scale predictor must be fitted without seeing calibration labels.
pub fn scaled_scores(
  truth : Array[Double],
  prediction : Array[Double],
  scale : Array[Double],
) -> Scores raise ConformalError {
  validate_values(truth, "truth")
  validate_values(prediction, "prediction")
  same_length(truth.length(), prediction.length())
  validate_scales(scale, truth.length())
  let residuals = []
  for i in 0..<truth.length() {
    let value = (truth[i] - prediction[i]).abs() / scale[i]
    if !finite(value) {
      raise Invalid("normalized residual overflow")
    }
    residuals.push(value)
  }
  Scores::new(residuals)
}

///|
pub fn predict_scaled(
  scores : Scores,
  prediction : Array[Double],
  scale : Array[Double],
  alpha : Double,
) -> Array[Interval] raise ConformalError {
  validate_values(prediction, "prediction")
  validate_scales(scale, prediction.length())
  let q = scores.threshold(alpha)
  if scores.sorted[0] < 0.0 {
    raise Invalid("normalized residual scores must be nonnegative")
  }
  let out = []
  for i in 0..<prediction.length() {
    let radius = q * scale[i]
    if finite(q) && !finite(radius) {
      raise Invalid("scaled radius overflow")
    }
    out.push(checked_interval(prediction[i], radius))
  }
  out
}
