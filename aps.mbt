///|
/// Stable order: larger probability first, then smaller label index.
/// Deterministic cumulative APS uses the full probability of the candidate label.
fn cumulative_scores(
  row : Array[Double],
  penalty : Double,
  regularized_after : Int32,
) -> Array[Double] raise ConformalError {
  let order = Array::makei(row.length(), i => i)
  order.sort_by((a, b) => {
    if row[a] > row[b] {
      -1
    } else if row[a] < row[b] {
      1
    } else {
      a - b
    }
  })
  let scores = Array::make(row.length(), 0.0)
  let mut mass = 0.0
  for rank in 0..<order.length() {
    let label = order[rank]
    mass = mass + row[label]
    let extra = if rank + 1 > regularized_after {
      (rank + 1 - regularized_after).to_double() * penalty
    } else {
      0.0
    }
    let score = mass + extra
    if !finite(score) {
      raise Invalid("regularized score overflow")
    }
    scores[label] = score
  }
  scores
}
