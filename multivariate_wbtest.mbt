///|
test "vector calibration uses rowwise maxima and frozen scales" {
  let model = calibrate_vectors(
    [[1.0, 4.0], [2.0, 2.0], [3.0, 0.0], [4.0, 6.0]],
    [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    [[1.0, 2.0], [1.0, 2.0], [1.0, 2.0], [1.0, 2.0]],
  )
  assert_eq(model.count(), 4)
  assert_eq(model.dimension(), 2)
  let box = model.predict([[10.0, 20.0]], [[1.0, 2.0]], 0.2)[0]
  assert_eq(box[0].lower, 6.0)
  assert_eq(box[1].upper, 28.0)
  assert_true(
    try {
      model.predict([[1.0, 2.0]], [[0.0, 1.0]], 0.2) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
