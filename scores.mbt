///|
/// Frozen sorted calibration values. The underlying array is never returned.
pub struct Scores {
  sorted : Array[Double]
}

///|
/// Accepts signed scores (needed by conformalized quantile regression).
pub fn Scores::new(values : Array[Double]) -> Scores raise ConformalError {
  validate_values(values, "scores")
  let sorted = values.copy()
  sorted.sort()
  { sorted, }
}

///|
pub fn Scores::count(self : Scores) -> Int32 {
  self.sorted.length()
}

///|
/// Defensive copy: mutating this result cannot alter a fitted calibrator.
pub fn Scores::values(self : Scores) -> Array[Double] {
  self.sorted.copy()
}

///|
/// One-based finite-sample rank. n+1 deliberately denotes positive infinity.
pub fn conformal_rank(n : Int32, alpha : Double) -> Int32 raise ConformalError {
  validate_alpha(alpha)
  if n < 1 || n > 100000 {
    raise Invalid("calibration size must be in 1..100000")
  }
  // Compare the discrete p-value grid directly, avoiding cancellation in 1-alpha.
  let denominator = (n + 1).to_double()
  let mut excluded = (denominator * alpha).floor().to_int()
  while excluded > 0 && excluded.to_double() / denominator > alpha {
    excluded = excluded - 1
  }
  while excluded < n && (excluded + 1).to_double() / denominator <= alpha {
    excluded = excluded + 1
  }
  n + 1 - excluded
}

///|
pub fn Scores::threshold(
  self : Scores,
  alpha : Double,
) -> Double raise ConformalError {
  let rank = conformal_rank(self.count(), alpha)
  if rank > self.count() {
    @double.infinity
  } else {
    self.sorted[rank - 1]
  }
}

///|
/// Conservative deterministic upper-tail p-value; includes all ties and +1.
pub fn Scores::p_value(
  self : Scores,
  score : Double,
) -> Double raise ConformalError {
  if !finite(score) {
    raise Invalid("candidate score must be finite")
  }
  let mut low = 0
  let mut high = self.count()
  while low < high {
    let mid = low + (high - low) / 2
    if self.sorted[mid] < score {
      low = mid + 1
    } else {
      high = mid
    }
  }
  (self.count() - low + 1).to_double() / (self.count() + 1).to_double()
}
