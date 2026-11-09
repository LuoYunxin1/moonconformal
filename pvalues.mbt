///|
/// Conservative label p-values retain ties; they are not class probabilities.
pub fn ClassCalibrator::p_values(
  self : ClassCalibrator,
  rows : Array[Array[Double]],
) -> Array[Array[Double]] raise ConformalError {
  validate_probability_batch(rows, self.classes)
  let out = []
  for row in rows {
    out.push(label_scores(row, self.rule).map(s => self.scores.p_value(s)))
  }
  out
}

///|
/// Generic score calibration for a user-defined, fixed nonconformity function.
/// Selection is p > alpha. Equality at the significance threshold is excluded.
pub fn select_by_p_value(
  calibration : Scores,
  candidates : Array[Double],
  alpha : Double,
) -> Array[Int32] raise ConformalError {
  validate_alpha(alpha)
  validate_values(candidates, "candidate scores")
  let selected = []
  for i in 0..<candidates.length() {
    if calibration.p_value(candidates[i]) > alpha {
      selected.push(i)
    }
  }
  selected
}

///|
/// Query nested real-line radii without refitting or changing calibration state.
pub fn threshold_path(
  scores : Scores,
  alphas : Array[Double],
) -> Array[Double] raise ConformalError {
  validate_values(alphas, "alphas")
  if alphas.length() > 1000 {
    raise ResourceLimit("at most 1000 significance levels per path")
  }
  alphas.map(alpha => scores.threshold(alpha))
}
