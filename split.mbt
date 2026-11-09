///| Explicit roles help detect accidental reuse of calibration labels in training.

///|
/// This validates supplied indices, not the internals of an external model.
pub struct DataSplit {
  size : Int32
  train : Array[Int32]
  calibration : Array[Int32]
  evaluation : Array[Int32]
}

///|
fn assign_role(
  indices : Array[Int32],
  role : Int32,
  seen : Array[Int32],
) -> Unit raise ConformalError {
  if indices.is_empty() {
    raise Invalid("every split role must have at least one row")
  }
  for index in indices {
    if index < 0 || index >= seen.length() {
      raise Invalid("split index out of range")
    }
    if seen[index] != 0 {
      raise Invalid("duplicate or overlapping split index")
    }
    seen[index] = role
  }
}

///|
/// Optional unused rows are allowed; all three supplied roles must be disjoint.
pub fn data_split(
  size : Int32,
  train : Array[Int32],
  calibration : Array[Int32],
  evaluation : Array[Int32],
) -> DataSplit raise ConformalError {
  if size < 3 || size > 1000000 {
    raise ResourceLimit("dataset size must be in 3..1000000")
  }
  if train.length() > size ||
    calibration.length() > size ||
    evaluation.length() > size {
    raise Invalid("split role longer than dataset")
  }
  let seen = Array::make(size, 0)
  assign_role(train, 1, seen)
  assign_role(calibration, 2, seen)
  assign_role(evaluation, 3, seen)
  {
    size,
    train: train.copy(),
    calibration: calibration.copy(),
    evaluation: evaluation.copy(),
  }
}

///|
pub fn DataSplit::sizes(self : DataSplit) -> (Int32, Int32, Int32) {
  (self.train.length(), self.calibration.length(), self.evaluation.length())
}

///|
/// Copies make the role validation stable after callers mutate their inputs.
pub fn DataSplit::indices(
  self : DataSplit,
) -> (Array[Int32], Array[Int32], Array[Int32]) {
  (self.train.copy(), self.calibration.copy(), self.evaluation.copy())
}

///|
/// Selects just the held-out calibration values in the explicitly supplied order.
pub fn DataSplit::calibration_values(
  self : DataSplit,
  values : Array[Double],
) -> Array[Double] raise ConformalError {
  same_length(values.length(), self.size)
  let result = self.calibration.map(i => values[i])
  validate_values(result, "selected calibration values")
  result
}

///|
pub fn DataSplit::evaluation_values(
  self : DataSplit,
  values : Array[Double],
) -> Array[Double] raise ConformalError {
  same_length(values.length(), self.size)
  let result = self.evaluation.map(i => values[i])
  validate_values(result, "selected evaluation values")
  result
}
