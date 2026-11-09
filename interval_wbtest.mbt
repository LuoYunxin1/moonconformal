///|
test "absolute regression produces closed sets and unbounded sentinel" {
  let s = absolute_scores([0.0, 3.0, 5.0, 7.0], [1.0, 1.0, 2.0, 3.0])
  let v = predict_absolute(s, [10.0], 0.2)[0]
  assert_eq(v.lower, 6.0)
  assert_eq(v.upper, 14.0)
  assert_true(v.contains(14.0))
  assert_eq(v.width(), 8.0)
  assert_true(predict_absolute(s, [1.0], 0.1)[0].width().is_pos_inf())
  assert_true(({ lower: 2.0, upper: 1.0, } : Interval).is_empty())
  assert_eq(v.intersect({ lower: 8.0, upper: 11.0, }).lower, 8.0)
}
