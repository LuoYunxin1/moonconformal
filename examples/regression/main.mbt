///|
/// Exported predictions may come from any independently trained regressor.
fn workflow() -> Unit raise @conformal.ConformalError {
  let split = @conformal.data_split(
    14,
    [0, 1],
    [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    [12, 13],
  )
  let truth = [
    0.0, 1.0, 2.0, 4.0, 5.0, 4.0, 7.0, 6.0, 9.0, 8.0, 11.0, 10.0, 13.0, 15.0,
  ]
  let prediction = [
    0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0,
  ]
  let scores = @conformal.absolute_scores(
    split.calibration_values(truth),
    split.calibration_values(prediction),
  )
  let intervals = @conformal.predict_absolute(
    scores,
    split.evaluation_values(prediction),
    0.2,
  )
  let report = @conformal.evaluate_intervals(
    split.evaluation_values(truth),
    intervals,
  )
  println(@conformal.intervals_to_json(intervals))
  println(@json.to_json([report.coverage, report.mean_width]).stringify())
  let restored = @conformal.Scores::from_snapshot(scores.to_snapshot())
  if restored.values() != scores.values() {
    abort("snapshot mismatch")
  }
}

///|
fn main {
  workflow() catch {
    _ => abort("regression workflow failed")
  }
}
