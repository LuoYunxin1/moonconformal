///|
fn workflow() -> Unit raise @conformal.ConformalError {
  let output : Array[Json] = []
  for (values, alpha) in oracle_cases() {
    let scores = @conformal.Scores::new(values)
    let q = scores.threshold(alpha)
    let threshold = if q.is_pos_inf() {
      Json::string("+inf")
    } else {
      Json::number(q)
    }
    output.push(
      Json::array([
        Json::number(
          @conformal.conformal_rank(values.length(), alpha).to_double(),
        ),
        threshold,
        @json.to_json(
          [-6.0, 0.0, 4.0, 10.0].map(candidate => scores.p_value(candidate)),
        ),
      ]),
    )
  }
  for
    row in [
      [0.8, 0.1, 0.1],
      [0.5, 0.5, 0.0],
      [0.25, 0.25, 0.25, 0.25],
      [0.0, 0.0, 1.0],
    ] {
    for rule in [@conformal.Lac, @conformal.Aps, @conformal.Raps(0.1, 1)] {
      output.push(@json.to_json(@conformal.label_scores(row, rule)))
    }
  }
  output.push(
    @json.to_json(
      @conformal.cqr_scores([2.0, 1.0, -1.0, 6.0], [0.0, 0.0, 0.0, 0.0], [
        4.0, 4.0, 4.0, 4.0,
      ]).values(),
    ),
  )
  output.push(
    @json.to_json(
      @conformal.scaled_scores([2.0, 8.0, 6.0, 16.0], [0.0, 0.0, 0.0, 0.0], [
        2.0, 4.0, 2.0, 4.0,
      ]).values(),
    ),
  )
  let cv = @conformal.cvplus_calibrate(
    [1.0, 2.0, 3.0, 4.0],
    [0.0, 0.0, 0.0, 0.0],
    [0, 1, 0, 1],
    2,
  )
  let interval = cv.predict([[10.0, 20.0]], 0.2)[0]
  output.push(@json.to_json([interval.lower, interval.upper]))
  let vector = @conformal.calibrate_vectors(
    [[1.0, 4.0], [2.0, 2.0], [3.0, 0.0], [4.0, 6.0]],
    [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    [[1.0, 2.0], [1.0, 2.0], [1.0, 2.0], [1.0, 2.0]],
  )
  let box = vector.predict([[10.0, 20.0]], [[1.0, 2.0]], 0.2)[0]
  output.push(
    @json.to_json([box[0].lower, box[0].upper, box[1].lower, box[1].upper]),
  )
  println(Json::array(output).stringify())
}

///|
fn main {
  workflow() catch {
    _ => abort("oracle execution failed")
  }
}
