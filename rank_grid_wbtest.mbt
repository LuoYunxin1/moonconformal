///|
test "rank follows the same discrete p-value grid at floating point boundaries" {
  let n = 10
  let alpha = 2.0 / 11.0
  assert_eq(conformal_rank(n, alpha), 9)
  for n in 1..<40 {
    for k in 1..<(n + 1) {
      let alpha = k.to_double() / (n + 1).to_double()
      let rank = conformal_rank(n, alpha)
      let scores = Scores::new(Array::makei(n, i => i.to_double()))
      let threshold = scores.threshold(alpha)
      for candidate in 0..<(n + 1) {
        assert_eq(
          candidate.to_double() <= threshold,
          scores.p_value(candidate.to_double()) > alpha,
        )
      }
      assert_eq(rank, n + 1 - k)
    }
  }
}
