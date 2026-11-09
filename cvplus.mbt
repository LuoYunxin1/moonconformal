///|
/// Frozen out-of-fold absolute residuals and their held-out model identifiers.
pub struct CvPlus {
  residuals : Array[Double]
  fold : Array[Int32]
  folds : Int32
}

///|
/// Every row's prediction must come from a model trained without that row.
pub fn cvplus_calibrate(
  truth : Array[Double],
  out_of_fold : Array[Double],
  fold : Array[Int32],
  folds : Int32,
) -> CvPlus raise ConformalError {
  let scores = absolute_scores(truth, out_of_fold)
  same_length(truth.length(), fold.length())
  if folds < 2 || folds > truth.length() || folds > 1000 {
    raise Invalid("CV+ folds must be in 2..min(n,1000)")
  }
  let counts = Array::make(folds, 0)
  let residuals = []
  for i in 0..<truth.length() {
    if fold[i] < 0 || fold[i] >= folds {
      raise Invalid("fold index out of range")
    }
    counts[fold[i]] = counts[fold[i]] + 1
    residuals.push((truth[i] - out_of_fold[i]).abs())
  }
  // Validation above also checks overflow; retain original row order, not sorted scores.
  if scores.count() != residuals.length() {
    raise Invalid("residual count mismatch")
  }
  for count in counts {
    if count == 0 {
      raise Invalid("every fold must have held-out rows")
    }
  }
  { residuals, fold: fold.copy(), folds, }
}

///|
pub fn CvPlus::count(self : CvPlus) -> Int32 {
  self.residuals.length()
}

///|
pub fn CvPlus::fold_count(self : CvPlus) -> Int32 {
  self.folds
}

///| test_by_fold[j][f] is model f's prediction for test row j.

///| Endpoints use lower floor((n+1)*alpha), upper ceil((n+1)*(1-alpha)).

///|
/// This implements the endpoint construction; it does not promise exact 1-alpha coverage.
pub fn CvPlus::predict(
  self : CvPlus,
  test_by_fold : Array[Array[Double]],
  alpha : Double,
) -> Array[Interval] raise ConformalError {
  validate_alpha(alpha)
  if alpha >= 0.5 {
    raise Invalid("CV+ endpoint alpha must be below 0.5")
  }
  if test_by_fold.is_empty() || test_by_fold.length() > 100000 {
    raise Invalid("empty or oversized CV+ batch")
  }
  if test_by_fold.length() > 2000000 / self.count() {
    raise ResourceLimit("CV+ batch exceeds two million candidate pairs")
  }
  let n = self.count()
  let high_rank = conformal_rank(n, alpha)
  let low_rank = n + 1 - high_rank
  let result = []
  for row in test_by_fold {
    validate_values(row, "fold predictions")
    same_length(row.length(), self.folds)
    let low = []
    let high = []
    for i in 0..<n {
      let lower = row[self.fold[i]] - self.residuals[i]
      let upper = row[self.fold[i]] + self.residuals[i]
      if !finite(lower) || !finite(upper) {
        raise Invalid("CV+ candidate overflow")
      }
      low.push(lower)
      high.push(upper)
    }
    low.sort()
    high.sort()
    result.push({
      lower: if low_rank < 1 {
        @double.neg_infinity
      } else {
        low[low_rank - 1]
      },
      upper: if high_rank > n {
        @double.infinity
      } else {
        high[high_rank - 1]
      },
    })
  }
  result
}
