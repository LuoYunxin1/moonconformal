///|
test "calibration state is frozen across every caller-visible score copy" {
  let values = [3.0, 1.0, 2.0]
  let scores = Scores::new(values)
  values[0] = 100.0
  let copy = scores.values()
  copy[0] = -100.0
  assert_eq(scores.values(), [1.0, 2.0, 3.0])
  assert_eq(scores.p_value(2.0), 0.75)
  assert_eq(scores.p_value(4.0), 0.25)
}

///|
test "all confidence APIs reject zero one NaN infinity and underflowed tails" {
  let scores = Scores::new([1.0, 2.0])
  for alpha in [0.0, 1.0, -0.1, @double.infinity, 0.0 / 0.0] {
    assert_true(
      try {
        scores.threshold(alpha) |> ignore
        false
      } catch {
        _ => true
      },
    )
  }
  let tails = tail_scores([1.0, 2.0], [0.0, 0.0])
  assert_true(
    try {
      predict_tails(tails, [0.0], 5.0e-324, 0.5) |> ignore
      false
    } catch {
      _ => true
    },
  )
}

///|
test "overflow crossing bounds shape and rule errors fail before returning output" {
  assert_true(
    try {
      absolute_scores([1.0e308], [-1.0e308]) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      predict_absolute(Scores::new([1.0e308]), [1.0e308], 0.5) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      cqr_scores([1.0], [2.0], [0.0]) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      scaled_scores([1.0], [0.0], [0.0]) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      label_scores([0.5, 0.5], Raps(-1.0, 0)) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      label_scores([0.5, 0.5], Raps(1.0, 3)) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      calibrate_classifier([[0.5, 0.5]], [2], Lac) |> ignore
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      calibrate_classifier([[0.5, 0.5], [0.2, 0.3, 0.5]], [0, 1], Aps) |> ignore
      false
    } catch {
      _ => true
    },
  )
}

///|
test "invalid snapshots reject excess fields nested shapes and silent numeric coercions" {
  for
    text in [
      "{\"schema\":1,\"kind\":\"scores\",\"scores\":[1],\"extra\":0}", "{\"schema\":1,\"kind\":\"scores\",\"scores\":[1e999]}",
      "{\"schema\":1,\"kind\":\"scores\",\"scores\":[true]}", "{\"schema\":1,\"kind\":\"scores\",\"scores\":[[1]]}",
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
  assert_true(
    try {
      sets_from_json(
        "{\"schema\":1,\"kind\":\"sets\",\"classes\":2,\"rows\":[[0,0]]}",
      )
      |> ignore
      false
    } catch {
      _ => true
    },
  )
}

///|
test "joint finite-sample boundaries include alpha equality and endpoint infinities" {
  let s = Scores::new([1.0, 2.0, 3.0, 4.0])
  assert_eq(s.threshold(0.2), 4.0)
  assert_true(s.threshold(0.199999999999).is_pos_inf())
  assert_eq(s.p_value(5.0), 0.2)
  assert_eq(select_by_p_value(s, [5.0, 4.0, 1.0], 0.2), [1, 2])
  let cqr = Scores::new([-2.0, -2.0, -2.0, -2.0])
  assert_true(predict_cqr(cqr, [0.0], [1.0], 0.2)[0].is_empty())
}

///|
test "CV+ uses a symmetric discrete p-value grid at fold endpoint boundaries" {
  let n = 10
  let truth = Array::makei(n, i => (i + 1).to_double())
  let folds = Array::makei(n, i => i % 2)
  let cv = cvplus_calibrate(truth, Array::make(n, 0.0), folds, 2)
  let alpha = 2.0 / 11.0
  let interval = cv.predict([[0.0, 0.0]], alpha)[0]
  assert_eq(interval.lower, -9.0)
  assert_eq(interval.upper, 9.0)
}
