///|
test "CV+ row-to-fold alignment and sentinel ranks" {
  let cv = cvplus_calibrate(
    [1.0, 2.0, 3.0, 4.0],
    [0.0, 0.0, 0.0, 0.0],
    [0, 1, 0, 1],
    2,
  )
  let result = cv.predict([[10.0, 20.0]], 0.2)[0]
  assert_eq(result.lower, 7.0)
  assert_eq(result.upper, 24.0)
  assert_eq(cv.fold_count(), 2)
  assert_true(cv.predict([[10.0, 20.0]], 0.1)[0].upper.is_pos_inf())
  assert_true(
    try {
      cvplus_calibrate([1.0, 2.0], [0.0, 0.0], [0, 0], 2) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
