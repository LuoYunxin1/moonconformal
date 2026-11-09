///|
test "resolution exposes finite-sample limits and nested interval paths" {
  let scores = Scores::new([1.0, 1.0, 2.0, 2.0])
  let report = scores.resolution(0.2)
  assert_eq(report.rank, 4)
  assert_eq(report.tied_at_threshold, 2)
  assert_eq(minimum_calibration_count(0.2), 4)
  assert_true(!scores.resolution(0.1).finite_threshold)
  let path = interval_path(scores, 10.0, [0.1, 0.2, 0.8])
  assert_true(path[0].upper >= path[1].upper && path[1].upper >= path[2].upper)
}
