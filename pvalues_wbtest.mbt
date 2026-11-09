///|
test "label p-values include ties and generic selection excludes equality" {
  let s = Scores::new([1.0, 2.0, 3.0, 4.0])
  assert_eq(select_by_p_value(s, [0.0, 4.0, 5.0], 0.2), [0, 1])
  let path = threshold_path(s, [0.8, 0.4, 0.1])
  assert_eq(path[0], 1.0)
  assert_eq(path[1], 3.0)
  assert_true(path[2].is_pos_inf())
  let m = calibrate_classifier([[0.8, 0.2]], [0], Lac)
  assert_eq(m.p_values([[0.8, 0.2]])[0], [1.0, 0.5])
}
