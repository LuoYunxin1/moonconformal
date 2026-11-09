///|
fn workflow() -> Unit raise @conformal.ConformalError {
  let groups = @conformal.grouped_scores([1.0, 2.0, 3.0, 4.0, 1.0], [
    "north", "north", "north", "north", "south",
  ])
  let restored = @conformal.GroupScores::from_snapshot(groups.to_snapshot())
  let intervals = @conformal.predict_grouped_absolute(
    restored,
    [10.0, 20.0],
    ["north", "south"],
    0.2,
  )
  println(@conformal.intervals_to_json(intervals))
  let reports = @conformal.evaluate_grouped_intervals([12.0, 25.0], intervals, [
    "north", "south",
  ])
  println(
    @json.to_json(reports.map(report => report.metrics.coverage)).stringify(),
  )
  let cv = @conformal.cvplus_calibrate(
    [1.0, 2.0, 3.0, 4.0],
    [0.0, 0.0, 0.0, 0.0],
    [0, 1, 0, 1],
    2,
  )
  println(@conformal.intervals_to_json(cv.predict([[10.0, 20.0]], 0.2)))
  let vectors = @conformal.calibrate_vectors(
    [[1.0, 2.0], [2.0, 1.0], [3.0, 2.0], [4.0, 3.0]],
    [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0], [0.0, 0.0]],
    [[1.0, 1.0], [1.0, 1.0], [1.0, 1.0], [1.0, 1.0]],
  )
  let rectangles = vectors.predict([[10.0, 20.0]], [[1.0, 2.0]], 0.2)
  println(@conformal.intervals_to_json(rectangles[0]))
}

///|
fn main {
  workflow() catch {
    _ => abort("platform workflow failed")
  }
}
