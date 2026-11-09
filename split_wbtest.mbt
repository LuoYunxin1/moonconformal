///|
test "explicit dataset roles prevent overlap without mutating callers" {
  let train = [0, 1]
  let split = data_split(6, train, [3, 2], [4])
  train[0] = 5
  assert_eq(split.indices().0, [0, 1])
  assert_eq(split.sizes(), (2, 2, 1))
  assert_eq(split.calibration_values([0.0, 1.0, 2.0, 3.0, 4.0, 5.0]), [3.0, 2.0])
  assert_true(
    try {
      data_split(5, [0], [0], [4]) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      data_split(5, [0], [1, 1], [4]) |> ignore
      false
    } catch {
      _ => true
    },
  )
}
