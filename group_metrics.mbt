///|
/// One empirical report per fixed group; group order is deterministic.
pub(all) struct GroupIntervalMetrics {
  group : String
  metrics : IntervalMetrics
}

///|
pub fn evaluate_grouped_intervals(
  truth : Array[Double],
  intervals : Array[Interval],
  groups : Array[String],
) -> Array[GroupIntervalMetrics] raise ConformalError {
  validate_values(truth, "group evaluation truth")
  same_length(truth.length(), intervals.length())
  same_length(truth.length(), groups.length())
  let indices : Map[String, Array[Int32]] = Map([])
  for i in 0..<groups.length() {
    if groups[i].length() == 0 || groups[i].length() > 256 {
      raise Invalid("invalid evaluation group name")
    }
    match indices.get(groups[i]) {
      Some(rows) => rows.push(i)
      None => indices.set(groups[i], [i])
    }
    if indices.length() > 10000 {
      raise ResourceLimit("too many evaluation groups")
    }
  }
  let names = []
  for name, _ in indices {
    names.push(name)
  }
  names.sort()
  let result = []
  for name in names {
    match indices.get(name) {
      None => raise UnknownGroup(name)
      Some(rows) => {
        let y = rows.map(i => truth[i])
        let sets = rows.map(i => intervals[i])
        result.push({ group: name, metrics: evaluate_intervals(y, sets), })
      }
    }
  }
  result
}

///|
/// Simultaneous coverage: a row is covered only when every coordinate is covered.
pub(all) struct VectorMetrics {
  count : Int32
  dimensions : Int32
  covered : Int32
  coverage : Double
  per_dimension : Array[IntervalMetrics]
}

///|
pub fn evaluate_vectors(
  truth : Array[Array[Double]],
  rectangles : Array[Array[Interval]],
) -> VectorMetrics raise ConformalError {
  if truth.is_empty() {
    raise Invalid("empty vector evaluation")
  }
  let dimensions = truth[0].length()
  validate_matrix(truth, truth.length(), dimensions, "vector evaluation truth")
  same_length(truth.length(), rectangles.length())
  let mut covered = 0
  for i in 0..<truth.length() {
    same_length(rectangles[i].length(), dimensions)
    let mut hit = true
    for j in 0..<dimensions {
      validate_interval(rectangles[i][j])
      if !rectangles[i][j].contains(truth[i][j]) {
        hit = false
      }
    }
    if hit {
      covered = covered + 1
    }
  }
  let per_dimension = []
  for j in 0..<dimensions {
    per_dimension.push(
      evaluate_intervals(
        truth.map(row => row[j]),
        rectangles.map(row => row[j]),
      ),
    )
  }
  {
    count: truth.length(),
    dimensions,
    covered,
    coverage: covered.to_double() / truth.length().to_double(),
    per_dimension,
  }
}
