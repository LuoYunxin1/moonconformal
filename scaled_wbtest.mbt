///|
test "normalized scores use test scales and reject zero" {
  let s = scaled_scores([2.0, 6.0, 12.0, 20.0], [0.0, 0.0, 0.0, 0.0], [
    1.0, 2.0, 3.0, 4.0,
  ])
  assert_eq(predict_scaled(s, [10.0], [2.0], 0.2)[0].lower, 0.0)
  assert_true(
    try {
      scaled_scores([1.0], [0.0], [0.0]) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
