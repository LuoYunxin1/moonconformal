///|
test "finite sample correction and ties" {
  let scores = Scores::new([1.0, 2.0, 3.0, 4.0])
  assert_eq(scores.threshold(0.2), 4.0)
  assert_true(scores.threshold(0.1).is_pos_inf())
  assert_eq(scores.p_value(3.0), 0.6)
  let copied = scores.values()
  copied[0] = 999.0
  assert_eq(scores.threshold(0.8), 1.0)
  assert_eq(conformal_rank(4, 0.2), 4)
}
