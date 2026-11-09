///|
test "prediction JSON preserves empty and infinite intervals and label vocabularies" {
  let intervals = [
    { lower: @double.neg_infinity, upper: @double.infinity, },
    { lower: 2.0, upper: 1.0, },
    { lower: -1.0, upper: 3.0, },
  ]
  let restored = intervals_from_json(intervals_to_json(intervals))
  assert_true(restored[0].upper.is_pos_inf())
  assert_true(restored[1].is_empty())
  assert_eq(restored[2].width(), 4.0)
  assert_eq(
    sets_from_json(sets_to_json([[1, 0], [], [2]], 3)),
    (3, [[1, 0], [], [2]]),
  )
  assert_true(
    try {
      intervals_from_json(
        "{\"schema\":1,\"kind\":\"intervals\",\"rows\":[{\"lower\":\"+inf\",\"upper\":1}]}",
      )
      |> ignore
      false
    } catch {
      _ => true
    },
  )
}
