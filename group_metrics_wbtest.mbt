///|
test "group reports and joint vector coverage expose marginal failures" {
  let interval = { lower: 0.0, upper: 1.0, }
  let groups = evaluate_grouped_intervals([0.0, 2.0], [interval, interval], [
    "b", "a",
  ])
  assert_eq(groups[0].group, "a")
  assert_eq(groups[0].metrics.coverage, 0.0)
  let vectors = evaluate_vectors([[0.0, 2.0], [2.0, 0.0]], [
    [interval, interval],
    [interval, interval],
  ])
  assert_eq(vectors.coverage, 0.0)
  assert_eq(vectors.per_dimension[0].coverage, 0.5)
}
