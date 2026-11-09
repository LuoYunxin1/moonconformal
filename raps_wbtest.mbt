///|
test "RAPS regularizes ranks and lambda zero equals APS" {
  assert_eq(label_scores([0.5, 0.3, 0.2], Raps(0.1, 1)), [0.5, 0.9, 1.2])
  assert_eq(
    label_scores([0.2, 0.8], Raps(0.0, 0)),
    label_scores([0.2, 0.8], Aps),
  )
  assert_true(
    try {
      label_scores([0.5, 0.5], Raps(-0.1, 0)) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
