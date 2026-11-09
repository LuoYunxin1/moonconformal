///|
test "Mondrian preserves small-group infinity and rejects unseen groups" {
  let groups = grouped_scores([1.0, 2.0, 3.0, 4.0, 5.0], [
    "large", "large", "large", "large", "small",
  ])
  assert_eq(groups.names(), ["large", "small"])
  assert_eq(groups.get("large").threshold(0.2), 4.0)
  assert_true(groups.get("small").threshold(0.2).is_pos_inf())
  let output = predict_grouped_absolute(
    groups,
    [10.0, 10.0],
    ["large", "small"],
    0.2,
  )
  assert_eq(output[0].lower, 6.0)
  assert_true(output[1].upper.is_pos_inf())
  assert_true(
    try {
      groups.get("unknown") |> ignore
      false
    } catch {
      _ => true
    },
  )
  let names = groups.names()
  names[0] = "changed"
  assert_eq(groups.names()[0], "large")
}
