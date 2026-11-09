///|
test "invalid alpha and nonfinite values reject" {
  assert_true(
    try {
      validate_alpha(0.0)
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      validate_values([@double.infinity], "scores")
      false
    } catch {
      _ => true
    },
  )
  validate_alpha(0.1)
  validate_values([0.0, -2.0], "scores")
}
