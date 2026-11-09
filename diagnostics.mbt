///|
/// Explains finite-sample resolution before selecting a model or confidence level.
pub(all) struct CalibrationResolution {
  count : Int32
  smallest_p_value : Double
  rank : Int32
  finite_threshold : Bool
  threshold : Double
  tied_at_threshold : Int32
}

///|
pub fn Scores::resolution(
  self : Scores,
  alpha : Double,
) -> CalibrationResolution raise ConformalError {
  let rank = conformal_rank(self.count(), alpha)
  let threshold = self.threshold(alpha)
  let mut ties = 0
  if finite(threshold) {
    for value in self.sorted {
      if value == threshold {
        ties = ties + 1
      }
    }
  }
  {
    count: self.count(),
    smallest_p_value: 1.0 / (self.count() + 1).to_double(),
    rank,
    finite_threshold: finite(threshold),
    threshold,
    tied_at_threshold: ties,
  }
}

///|
/// Smallest n within the supported budget admitting a finite corrected threshold.
pub fn minimum_calibration_count(alpha : Double) -> Int32 raise ConformalError {
  validate_alpha(alpha)
  if conformal_rank(100000, alpha) > 100000 {
    raise ResourceLimit(
      "requested alpha requires more than 100000 calibration rows",
    )
  }
  let mut low = 1
  let mut high = 100000
  while low < high {
    let mid = low + (high - low) / 2
    if conformal_rank(mid, alpha) <= mid {
      high = mid
    } else {
      low = mid + 1
    }
  }
  low
}

///|
/// Nonempty alpha grid in caller order; no sorting or deduplication changes semantics.
pub fn interval_path(
  scores : Scores,
  prediction : Double,
  levels : Array[Double],
) -> Array[Interval] raise ConformalError {
  if levels.is_empty() || levels.length() > 1000 {
    raise ResourceLimit("confidence path requires 1..1000 levels")
  }
  if !finite(prediction) {
    raise Invalid("path prediction must be finite")
  }
  if scores.sorted[0] < 0.0 {
    raise Invalid("interval path requires nonnegative residual scores")
  }
  levels.map(alpha => checked_interval(prediction, scores.threshold(alpha)))
}
