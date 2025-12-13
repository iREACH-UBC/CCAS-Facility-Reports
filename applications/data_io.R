#' Checks if unprocessed sensor data came from Github based on the
#'  dataset's column names. Is a simplified check to be used when
#'  comparing with manually generated sensor data. Checks if both
#'  column components and order are equal to Git data columns.
#'
#' @param column_names A vector (char) of dataset column names.
#' @return TRUE if data columns align with Github data columns, FALSE otherwise.
sensor_data_is_from_git <- function(column_names) {
  git_cols_1 <- c(
    "DATE", "CO", "NO", "NO2", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
    "O3_contrib", "PM2_5_contrib", "Top_AQHI_Contributor"
  )
  git_cols_2 <- git_cols_1 |> replace(12, "Top_AQHI_contributor")

  isTRUE(all.equal(column_names, git_cols_1)) || isTRUE(
    all.equal(column_names, git_cols_2)
  )
}


#' Checks if unprocessed sensor data came from manual calibrations based on the
#'  dataset's column names. Is a simplified check to be used when
#'  comparing with sensor data from Github. Checks if both column components
#'  and order are equal to manually calibrated data columns
#'
#' @param column_names A vector (char) of dataset column names.
#' @return TRUE if data columns align with manually calibrated data
#'  columns, FALSE otherwise.
sensor_data_manually_generated <- function(column_names) {
  manual_data_cols <- c("date", "NO2", "NO", "CO2", "O3", "CO", "PM2_5")
  isTRUE(all.equal(column_names, manual_data_cols))
}