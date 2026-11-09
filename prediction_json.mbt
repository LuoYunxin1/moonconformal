///|
/// Infinite interval endpoints use explicit strings; JSON numbers remain finite.
fn endpoint_json(value : Double) -> Json {
  if value.is_pos_inf() {
    Json::string("+inf")
  } else if value == @double.neg_infinity {
    Json::string("-inf")
  } else {
    Json::number(value)
  }
}

///|
fn endpoint_from_json(value : Json) -> Double raise ConformalError {
  match value {
    String("+inf") => @double.infinity
    String("-inf") => @double.neg_infinity
    Number(number, ..) =>
      if finite(number) {
        number
      } else {
        raise Invalid("nonfinite JSON number")
      }
    _ =>
      raise Invalid(
        "interval endpoint must be finite or an explicit infinity string",
      )
  }
}

///|
/// Valid empty sets retain their endpoints; unbounded sets do not become null.
pub fn intervals_to_json(
  intervals : Array[Interval],
) -> String raise ConformalError {
  if intervals.is_empty() || intervals.length() > 100000 {
    raise ResourceLimit("interval export size outside 1..100000")
  }
  let rows = []
  for interval in intervals {
    validate_interval(interval)
    rows.push(
      Json::object(
        Map([
          ("lower", endpoint_json(interval.lower)),
          ("upper", endpoint_json(interval.upper)),
        ]),
      ),
    )
  }
  Json::object(
    Map([
      ("schema", Json::number(1.0)),
      ("kind", Json::string("intervals")),
      ("rows", Json::array(rows)),
    ]),
  ).stringify()
}

///|
/// Same bounded strict parser as calibration snapshots.
pub fn intervals_from_json(
  text : String,
) -> Array[Interval] raise ConformalError {
  let fields = snapshot_object(snapshot_parse(text), ["schema", "kind", "rows"])
  snapshot_version(fields, "intervals")
  match snapshot_field(fields, "rows") {
    Array(rows) => {
      if rows.is_empty() || rows.length() > 100000 {
        raise ResourceLimit("interval import size outside 1..100000")
      }
      let result = []
      for row in rows {
        let fields = snapshot_object(row, ["lower", "upper"])
        let interval = {
          lower: endpoint_from_json(snapshot_field(fields, "lower")),
          upper: endpoint_from_json(snapshot_field(fields, "upper")),
        }
        validate_interval(interval)
        result.push(interval)
      }
      result
    }
    _ => raise Invalid("interval rows must be an array")
  }
}

///|
/// Label sets have a schema and a fixed class vocabulary size.
pub fn sets_to_json(
  sets : Array[Array[Int32]],
  classes : Int32,
) -> String raise ConformalError {
  if classes < 2 || classes > 1024 {
    raise Invalid("invalid export class count")
  }
  if sets.is_empty() ||
    sets.length() > 100000 ||
    sets.length() > 2000000 / classes {
    raise ResourceLimit("set export exceeds supported budget")
  }
  let rows = []
  for labels in sets {
    validate_label_set(labels, classes)
    rows.push(Json::array(labels.map(label => Json::number(label.to_double()))))
  }
  Json::object(
    Map([
      ("schema", Json::number(1.0)),
      ("kind", Json::string("sets")),
      ("classes", Json::number(classes.to_double())),
      ("rows", Json::array(rows)),
    ]),
  ).stringify()
}

///|
/// Returns class vocabulary size with the validated prediction sets.
pub fn sets_from_json(
  text : String,
) -> (Int32, Array[Array[Int32]]) raise ConformalError {
  let fields = snapshot_object(snapshot_parse(text), [
    "schema", "kind", "classes", "rows",
  ])
  snapshot_version(fields, "sets")
  let classes = snapshot_integer(snapshot_field(fields, "classes"), 2, 1024)
  match snapshot_field(fields, "rows") {
    Array(rows) => {
      if rows.is_empty() ||
        rows.length() > 100000 ||
        rows.length() > 2000000 / classes {
        raise ResourceLimit("set import exceeds supported budget")
      }
      let result = []
      for row in rows {
        match row {
          Array(labels) => {
            if labels.length() > classes {
              raise Invalid("too many labels in imported set")
            }
            let labels = labels.map(label => {
              snapshot_integer(label, 0, classes - 1)
            })
            validate_label_set(labels, classes)
            result.push(labels)
          }
          _ => raise Invalid("each prediction set must be an array")
        }
      }
      (classes, result)
    }
    _ => raise Invalid("prediction sets must be an array")
  }
}
