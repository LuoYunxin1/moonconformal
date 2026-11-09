///|
/// Stable input failures. No invalid input silently falls back to another method.
pub(all) suberror ConformalError {
  Invalid(String)
  ResourceLimit(String)
  UnknownGroup(String)
} derive(Debug)

///|
pub extend ConformalError with @debug.Debug::{to_repr}

///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn validate_alpha(alpha : Double) -> Unit raise ConformalError {
  if !finite(alpha) || alpha <= 0.0 || alpha >= 1.0 {
    raise Invalid("alpha must be finite and strictly between zero and one")
  }
}

///|
fn validate_values(
  values : Array[Double],
  name : String,
) -> Unit raise ConformalError {
  if values.is_empty() {
    raise Invalid(name + " must not be empty")
  }
  if values.length() > 100000 {
    raise ResourceLimit(name + " exceeds 100000 elements")
  }
  for value in values {
    if !finite(value) {
      raise Invalid(name + " contains a nonfinite value")
    }
  }
}
