///|
/// Entries are sorted by group name so exports are reproducible.
pub fn GroupScores::to_snapshot(
  self : GroupScores,
) -> String raise ConformalError {
  let entries = []
  for name in self.names {
    entries.push(
      Json::object(
        Map([
          ("name", Json::string(name)),
          (
            "scores",
            Json::array(self.get(name).sorted.map(x => Json::number(x))),
          ),
        ]),
      ),
    )
  }
  Json::object(
    Map([
      ("schema", Json::number(1.0)),
      ("kind", Json::string("groups")),
      ("groups", Json::array(entries)),
    ]),
  ).stringify()
}

///|
/// Applies one global score budget, in addition to per-group validation.
pub fn GroupScores::from_snapshot(
  text : String,
) -> GroupScores raise ConformalError {
  let fields = snapshot_object(snapshot_parse(text), [
    "schema", "kind", "groups",
  ])
  snapshot_version(fields, "groups")
  let values = []
  let labels = []
  let seen : Map[String, Bool] = Map([])
  match snapshot_field(fields, "groups") {
    Array(entries) => {
      if entries.is_empty() || entries.length() > 10000 {
        raise Invalid("snapshot group count outside range")
      }
      for entry in entries {
        let fields = snapshot_object(entry, ["name", "scores"])
        let name = match snapshot_field(fields, "name") {
          String(name) => name
          _ => raise Invalid("snapshot group name must be a string")
        }
        if seen.contains(name) {
          raise Invalid("duplicate snapshot group name")
        }
        seen.set(name, true)
        let scores = snapshot_scores(snapshot_field(fields, "scores"))
        if values.length() + scores.count() > 100000 {
          raise ResourceLimit("total snapshot scores exceed 100000")
        }
        for value in scores.sorted {
          values.push(value)
          labels.push(name)
        }
      }
    }
    _ => raise Invalid("snapshot groups must be an array")
  }
  grouped_scores(values, labels)
}
