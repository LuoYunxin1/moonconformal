///|
test "group snapshots are stable and reject duplicate groups" {
  let groups = grouped_scores([3.0, 1.0, 2.0], ["b", "a", "a"])
  let text = groups.to_snapshot()
  assert_eq(GroupScores::from_snapshot(text).to_snapshot(), text)
  assert_eq(GroupScores::from_snapshot(text).get("a").values(), [1.0, 2.0])
  assert_true(
    try {
      GroupScores::from_snapshot(
        "{\"schema\":1,\"kind\":\"groups\",\"groups\":[{\"name\":\"a\",\"scores\":[1]},{\"name\":\"a\",\"scores\":[2]}]}",
      )
      |> ignore
      false
    } catch {
      _ => true
    },
  )
}
