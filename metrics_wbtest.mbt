///|
test "empirical metrics count empty unbounded and duplicate sets correctly" {
  let report = evaluate_intervals([1.0, 2.0, 3.0], [
    { lower: 0.0, upper: 1.0, },
    { lower: 4.0, upper: 3.0, },
    { lower: @double.neg_infinity, upper: @double.infinity, },
  ])
  assert_eq(report.covered, 2)
  assert_eq(report.empty, 1)
  assert_eq(report.unbounded, 1)
  assert_true(report.mean_width.is_pos_inf())
  assert_eq(interval_score({ lower: 0.0, upper: 2.0, }, 3.0, 0.2), 12.0)
  let sets = evaluate_sets([0, 1, 0], [[0], [0, 1], []], 2)
  assert_eq(sets.covered, 2)
  assert_eq(sets.singleton_accuracy, Some(1.0))
  assert_true(
    try {
      evaluate_sets([0], [[0, 0]], 2) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      evaluate_intervals([0.0], [{ lower: 0.0 / 0.0, upper: 1.0, }]) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
