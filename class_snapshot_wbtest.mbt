///|
test "classification snapshots retain RAPS rule and validate parameters" {
  let model = calibrate_classifier(
    [[0.7, 0.3], [0.4, 0.6]],
    [0, 1],
    Raps(0.1, 1),
  )
  let restored = ClassCalibrator::from_snapshot(model.to_snapshot())
  assert_eq(
    restored.predict([[0.5, 0.5]], 0.4),
    model.predict([[0.5, 0.5]], 0.4),
  )
  assert_true(
    try {
      ClassCalibrator::from_snapshot(
        "{\"schema\":1,\"kind\":\"classifier\",\"classes\":2.5,\"rule\":\"lac\",\"penalty\":0,\"after\":0,\"scores\":[0.1]}",
      )
      |> ignore
      false
    } catch {
      _ => true
    },
  )
}
