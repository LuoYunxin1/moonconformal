///|
fn workflow() -> Unit raise @conformal.ConformalError {
  let rows = [
    [0.8, 0.1, 0.1],
    [0.1, 0.8, 0.1],
    [0.1, 0.2, 0.7],
    [0.6, 0.3, 0.1],
    [0.2, 0.6, 0.2],
    [0.1, 0.3, 0.6],
    [0.7, 0.2, 0.1],
    [0.1, 0.7, 0.2],
    [0.2, 0.1, 0.7],
    [0.5, 0.3, 0.2],
  ]
  let truth = [0, 1, 2, 0, 1, 2, 0, 1, 2, 0]
  let query = [[0.8, 0.1, 0.1], [0.4, 0.35, 0.25]]
  for rule in [@conformal.Lac, @conformal.Aps, @conformal.Raps(0.02, 1)] {
    let model = @conformal.calibrate_classifier(rows, truth, rule)
    let sets = model.predict(query, 0.2)
    println(@conformal.sets_to_json(sets, 3))
    println(@json.to_json(model.p_values(query)).stringify())
    let report = @conformal.evaluate_sets([0, 1], sets, 3)
    println(@json.to_json([report.coverage, report.mean_size]).stringify())
    // Downstream services may route non-singletons to human review.
    println(@json.to_json(sets.map(labels => labels.length() != 1)).stringify())
  }
}

///|
fn main {
  workflow() catch {
    _ => abort("classification workflow failed")
  }
}
