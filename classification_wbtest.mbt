///|
test "LAC produces label sets with finite-sample correction" {
  let model = calibrate_classifier(
    [[0.8, 0.2], [0.6, 0.4], [0.7, 0.3], [0.9, 0.1]],
    [0, 0, 0, 0],
    Lac,
  )
  assert_eq(model.count(), 4)
  assert_eq(model.class_count(), 2)
  assert_eq(model.predict([[0.7, 0.3]], 0.2)[0], [0])
  assert_eq(model.predict([[0.7, 0.3]], 0.1)[0], [0, 1])
  assert_true(
    try {
      label_scores([0.1, 0.1], Lac) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
