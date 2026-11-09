///|
test "score snapshots roundtrip signed values and reject schema corruption" {
  let original = Scores::new([3.0, -1.0, 2.0])
  assert_eq(Scores::from_snapshot(original.to_snapshot()).values(), [
    -1.0, 2.0, 3.0,
  ])
  for
    text in [
      "{}", "{\"schema\":2,\"kind\":\"scores\",\"scores\":[1]}", "{\"schema\":1,\"kind\":\"scores\",\"scores\":[]}",
      "{\"schema\":1,\"schema\":1,\"kind\":\"scores\",\"scores\":[1]}",
    ] {
    assert_true(
      try {
        Scores::from_snapshot(text) |> ignore
        false
      } catch {
        _ => true
      },
    )
  }
}
