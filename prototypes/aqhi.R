# Contains an updated function to calculate AQHI. Function looks
#  at time rather than number of data points to more accurately
#  get AQHI. Function needs to be tested.

#' Gets AQHI values given sensor data. Used for sensor data
#'  missing an AQHI column.
#'
#' @param dataset A dataframe of calibrated sensor data. Must have
#'  date, NO2, O3, and PM2.5 columns.
#' @return Vector of AQHI values (int). Each index of the vector
#'  corresponds to a row in the dataset.
#' @export
get_aqhi_column <- function(dataset) {
  # Helper function that takes higher of two AQHI calculations
  apply_aqhi_ceiling <- function(aqhi_vec, pm25_1h_vec) {
    pmax(aqhi_vec, ceiling(pm25_1h_vec / 10)) |> round()
  }
  # Take pollutant and PM averages
  # Rolling average that accounts for missing data
  no2_3h <- slider::slide_index_dbl(
    .x = dataset$NO2, # values
    .i = dataset$date, # time index
    .f = ~ mean(.x, na.rm = TRUE),
    .before = lubridate::hours(3), # include 3 hours back
    .complete = TRUE
  )
  o3_3h <- slider::slide_index_dbl(
    .x = dataset$O3, # values
    .i = dataset$date, # time index
    .f = ~ mean(.x, na.rm = TRUE),
    .before = lubridate::hours(3), # include 3 hours back
    .complete = TRUE
  )
  pm2_5_3h <- slider::slide_index_dbl(
    .x = dataset$PM2_5, # values
    .i = dataset$date, # time index
    .f = ~ mean(.x, na.rm = TRUE),
    .before = lubridate::hours(3), # include 3 hours back
    .complete = TRUE
  )
  pm2_5_1h <- slider::slide_index_dbl(
    .x = dataset$PM2_5, # values
    .i = dataset$date, # time index
    .f = ~ mean(.x, na.rm = TRUE),
    .before = lubridate::hours(1), # include 3 hours back
    .complete = TRUE
  )
  # Calculate AQHI
  aqhi_val <- (10 / 10.4) * 100 * (
    (exp(0.000871 * no2_3h) - 1) +
    (exp(0.000537 * o3_3h) - 1) +
    (exp(0.000487 * pm2_5_3h) - 1)
  )
  invisible(mapply(apply_aqhi_ceiling, aqhi_val, pm2_5_1h))
}