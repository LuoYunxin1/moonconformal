///|
test "absolute and scaled prediction reject any negative score even below selected rank" {
  let scores = Scores::new([-1.0, 1.0, 2.0, 3.0])
  assert_true(
    try {
      predict_absolute(scores, [0.0], 0.2) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      predict_scaled(scores, [0.0], [1.0], 0.2) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      predict_absolute(scores, [0.0], 0.01) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
