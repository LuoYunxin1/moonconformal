///|
test "APS ties are resolved by label index including zero mass" {
  assert_eq(label_scores([0.5, 0.5, 0.0], Aps), [0.5, 1.0, 1.0])
  let m = calibrate_classifier(
    [[0.8, 0.2], [0.8, 0.2], [0.8, 0.2], [0.8, 0.2]],
    [0, 0, 0, 0],
    Aps,
  )
  assert_eq(m.predict([[0.7, 0.3]], 0.2)[0], [0])
}
