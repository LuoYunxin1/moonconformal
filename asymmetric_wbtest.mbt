///|
test "two separately calibrated tails retain signed residuals" {
  let s = tail_scores([1.0, 2.0, 3.0, 4.0], [0.0, 0.0, 0.0, 0.0])
  assert_eq(s.count(), 4)
  let p = predict_tails(s, [10.0], 0.4, 0.5)[0]
  assert_eq(p.lower, 11.0)
  assert_eq(p.upper, 14.0)
}
