///|
/// Simultaneous rectangular sets from one maximum normalized score per row.
pub struct VectorCalibrator {
  scores : Scores
  dimensions : Int32
}

///|
fn validate_matrix(
  matrix : Array[Array[Double]],
  rows : Int32,
  columns : Int32,
  name : String,
) -> Unit raise ConformalError {
  if rows < 1 || rows > 100000 || columns < 1 || columns > 1024 {
    raise Invalid("matrix shape outside supported range")
  }
  if rows > 2000000 / columns {
    raise ResourceLimit("matrix exceeds two million cells")
  }
  same_length(matrix.length(), rows)
  for row in matrix {
    same_length(row.length(), columns)
    validate_values(row, name)
  }
}

///|
/// Scales must be fixed or trained independently of calibration outcomes.
pub fn calibrate_vectors(
  truth : Array[Array[Double]],
  prediction : Array[Array[Double]],
  scale : Array[Array[Double]],
) -> VectorCalibrator raise ConformalError {
  if truth.is_empty() {
    raise Invalid("empty vector calibration")
  }
  let n = truth.length()
  let dimensions = truth[0].length()
  validate_matrix(truth, n, dimensions, "vector truth")
  validate_matrix(prediction, n, dimensions, "vector prediction")
  validate_matrix(scale, n, dimensions, "vector scale")
  let values = []
  for i in 0..<n {
    let mut maximum = 0.0
    for j in 0..<dimensions {
      if scale[i][j] <= 0.0 {
        raise Invalid("vector scales must be positive")
      }
      let value = (truth[i][j] - prediction[i][j]).abs() / scale[i][j]
      if !finite(value) {
        raise Invalid("vector residual overflow")
      }
      if value > maximum {
        maximum = value
      }
    }
    values.push(maximum)
  }
  { scores: Scores::new(values), dimensions, }
}

///|
pub fn VectorCalibrator::dimension(self : VectorCalibrator) -> Int32 {
  self.dimensions
}

///|
pub fn VectorCalibrator::count(self : VectorCalibrator) -> Int32 {
  self.scores.count()
}

///|
/// Each returned row is a rectangle, with joint rather than marginal calibration.
pub fn VectorCalibrator::predict(
  self : VectorCalibrator,
  prediction : Array[Array[Double]],
  scale : Array[Array[Double]],
  alpha : Double,
) -> Array[Array[Interval]] raise ConformalError {
  validate_matrix(
    prediction,
    prediction.length(),
    self.dimensions,
    "vector prediction",
  )
  validate_matrix(scale, prediction.length(), self.dimensions, "vector scale")
  let q = self.scores.threshold(alpha)
  let result = []
  for i in 0..<prediction.length() {
    let rectangle = []
    for j in 0..<self.dimensions {
      if scale[i][j] <= 0.0 {
        raise Invalid("vector scales must be positive")
      }
      let radius = q * scale[i][j]
      if finite(q) && !finite(radius) {
        raise Invalid("vector radius overflow")
      }
      rectangle.push(checked_interval(prediction[i][j], radius))
    }
    result.push(rectangle)
  }
  result
}
