///|
/// A bounded, versioned JSON transport; snapshots contain calibration scores only.
fn snapshot_parse(text : String) -> Json raise ConformalError {
  if text.length() > 4000000 {
    raise ResourceLimit("snapshot exceeds four million code units")
  }
  @json.parse(text, max_nesting_depth=12, reject_duplicate_keys=true) catch {
    _ => raise Invalid("invalid snapshot JSON")
  }
}

///|
fn snapshot_object(
  value : Json,
  keys : Array[String],
) -> Map[String, Json] raise ConformalError {
  match value {
    Object(fields) => {
      if fields.length() != keys.length() {
        raise Invalid("snapshot fields do not match schema")
      }
      for key in keys {
        if !fields.contains(key) {
          raise Invalid("missing snapshot field: " + key)
        }
      }
      fields
    }
    _ => raise Invalid("snapshot must be an object")
  }
}

///|
fn snapshot_field(
  fields : Map[String, Json],
  key : String,
) -> Json raise ConformalError {
  match fields.get(key) {
    Some(value) => value
    None => raise Invalid("missing snapshot field: " + key)
  }
}

///|
fn snapshot_number(value : Json) -> Double raise ConformalError {
  match value {
    Number(number, ..) =>
      if finite(number) {
        number
      } else {
        raise Invalid("nonfinite snapshot number")
      }
    _ => raise Invalid("expected snapshot number")
  }
}

///|
fn snapshot_scores(value : Json) -> Scores raise ConformalError {
  match value {
    Array(values) => {
      if values.length() > 100000 {
        raise ResourceLimit("snapshot score limit exceeded")
      }
      Scores::new(values.map(snapshot_number))
    }
    _ => raise Invalid("snapshot scores must be an array")
  }
}

///|
fn snapshot_version(
  fields : Map[String, Json],
  kind : String,
) -> Unit raise ConformalError {
  if snapshot_number(snapshot_field(fields, "schema")) != 1.0 {
    raise Invalid("unsupported snapshot schema")
  }
  match snapshot_field(fields, "kind") {
    String(value) => if value != kind { raise Invalid("wrong snapshot kind") }
    _ => raise Invalid("invalid snapshot kind")
  }
}

///|
/// Scores are finite, signed, and sorted; alpha is chosen at prediction time.
pub fn Scores::to_snapshot(self : Scores) -> String {
  Json::object(
    Map([
      ("schema", Json::number(1.0)),
      ("kind", Json::string("scores")),
      ("scores", Json::array(self.sorted.map(x => Json::number(x)))),
    ]),
  ).stringify()
}

///|
/// Rejects unknown fields, duplicate keys, nonfinite numbers and resource excess.
pub fn Scores::from_snapshot(text : String) -> Scores raise ConformalError {
  let fields = snapshot_object(snapshot_parse(text), [
    "schema", "kind", "scores",
  ])
  snapshot_version(fields, "scores")
  snapshot_scores(snapshot_field(fields, "scores"))
}
