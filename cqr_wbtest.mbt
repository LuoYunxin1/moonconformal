///|
test "CQR preserves negative scores and empty predictions" {
  let s = cqr_scores([0.0, 0.0, 0.0, 0.0], [-3.0, -3.0, -3.0, -3.0], [
    3.0, 3.0, 3.0, 3.0,
  ])
  assert_eq(s.threshold(0.2), -3.0)
  let p = predict_cqr(s, [-1.0], [1.0], 0.2)[0]
  assert_true(p.is_empty())
  assert_eq(p.width(), 0.0)
  assert_true(!p.contains(0.0))
}
