///|
/// Empirical diagnostics, not estimates of a universal conditional guarantee.
pub(all) struct IntervalMetrics {
  count : Int32
  covered : Int32
  empty : Int32
  unbounded : Int32
  mean_width : Double
  coverage : Double
}

///|
/// NaN and infinities with the wrong orientation are not valid prediction sets.
fn validate_interval(interval : Interval) -> Unit raise ConformalError {
  if interval.lower.is_nan() || interval.upper.is_nan() {
    raise Invalid("NaN interval endpoint")
  }
  if interval.lower.is_pos_inf() || interval.upper == @double.neg_infinity {
    raise Invalid("invalid infinite endpoint orientation")
  }
}

///|
/// Count infinities separately; an unbounded set makes mean_width infinite.
pub fn evaluate_intervals(
  truth : Array[Double],
  intervals : Array[Interval],
) -> IntervalMetrics raise ConformalError {
  validate_values(truth, "evaluation truth")
  same_length(truth.length(), intervals.length())
  let mut covered = 0
  let mut empty = 0
  let mut unbounded = 0
  let mut mean = 0.0
  for i in 0..<truth.length() {
    let interval = intervals[i]
    validate_interval(interval)
    if interval.contains(truth[i]) {
      covered = covered + 1
    }
    if interval.is_empty() {
      empty = empty + 1
    }
    let width = interval.width()
    if interval.lower.is_inf() || interval.upper.is_inf() {
      unbounded = unbounded + 1
    }
    // Divide before summation to reduce overflow for large finite widths.
    mean = mean + width / truth.length().to_double()
  }
  {
    count: truth.length(),
    covered,
    empty,
    unbounded,
    mean_width: mean,
    coverage: covered.to_double() / truth.length().to_double(),
  }
}

///|
/// Winkler/interval score for nonempty intervals; empty sets have no such score.
pub fn interval_score(
  interval : Interval,
  truth : Double,
  alpha : Double,
) -> Double raise ConformalError {
  validate_alpha(alpha)
  validate_interval(interval)
  if !finite(truth) {
    raise Invalid("interval score truth must be finite")
  }
  if interval.is_empty() {
    raise Invalid("interval score undefined for an empty set")
  }
  if interval.lower.is_inf() || interval.upper.is_inf() {
    return @double.infinity
  }
  let miss = if truth < interval.lower {
    interval.lower - truth
  } else if truth > interval.upper {
    truth - interval.upper
  } else {
    0.0
  }
  interval.width() + 2.0 * miss / alpha
}

///|
pub(all) struct SetMetrics {
  count : Int32
  covered : Int32
  empty : Int32
  singletons : Int32
  mean_size : Double
  coverage : Double
  singleton_accuracy : Double?
}

///|
/// Duplicated labels are invalid rather than artificially increasing set size.
fn validate_label_set(
  labels : Array[Int32],
  classes : Int32,
) -> Unit raise ConformalError {
  if labels.length() > classes {
    raise Invalid("prediction set exceeds class count")
  }
  let seen = Array::make(classes, false)
  for label in labels {
    if label < 0 || label >= classes {
      raise Invalid("prediction set label out of range")
    }
    if seen[label] {
      raise Invalid("duplicate prediction set label")
    }
    seen[label] = true
  }
}

///|
pub fn evaluate_sets(
  truth : Array[Int32],
  sets : Array[Array[Int32]],
  classes : Int32,
) -> SetMetrics raise ConformalError {
  if truth.is_empty() || truth.length() > 100000 {
    raise Invalid("evaluation size must be in 1..100000")
  }
  if classes < 2 || classes > 1024 {
    raise Invalid("invalid evaluation class count")
  }
  if truth.length() > 2000000 / classes {
    raise ResourceLimit("set evaluation exceeds two million class checks")
  }
  same_length(truth.length(), sets.length())
  let mut covered = 0
  let mut empty = 0
  let mut singletons = 0
  let mut singleton_hits = 0
  let mut total_size = 0
  for i in 0..<truth.length() {
    if truth[i] < 0 || truth[i] >= classes {
      raise Invalid("evaluation label out of range")
    }
    validate_label_set(sets[i], classes)
    let hit = sets[i].contains(truth[i])
    if hit {
      covered = covered + 1
    }
    if sets[i].is_empty() {
      empty = empty + 1
    }
    if sets[i].length() == 1 {
      singletons = singletons + 1
      if hit {
        singleton_hits = singleton_hits + 1
      }
    }
    total_size = total_size + sets[i].length()
  }
  {
    count: truth.length(),
    covered,
    empty,
    singletons,
    mean_size: total_size.to_double() / truth.length().to_double(),
    coverage: covered.to_double() / truth.length().to_double(),
    singleton_accuracy: if singletons == 0 {
      None
    } else {
      Some(singleton_hits.to_double() / singletons.to_double())
    },
  }
}
