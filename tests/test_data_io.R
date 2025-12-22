options(testthat.edition = 3)
testthat::context("Test file-related applications")
source("applications/data_io.R")


patrick::with_parameters_test_that(
  desc_stub = "Test sensor_data_from_git",
  .cases = tibble::tibble(
    col_names = list(
      c(
        "DATE", "CO", "NO", "NO2", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
        "O3_contrib", "PM2_5_contrib", "Top_AQHI_Contributor"),
      c(
        "date", "CO", "NO", "NO2", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
        "O3_contrib", "PM2_5_contrib", "Top_AQHI_contributor"),
      c(
        "DATE", "CO", "NO", "NO3", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
        "O3_contrib", "PM2_5_contrib", "Top_AQHI_Contributor"),
      c(
        "DATE", "CO", "NO", "NO2", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
        "O3_contrib", "PM2_5_contrib", "Top_AQHI_contributor"),
      c(
        "DATE", "CO", "NO", "NO2", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
        "O3_contrib", "PM2_5_contrib", "Top_AQHI_contributor", "Extra"),
      c(
        "DATE", "CO", "NO", "NO2", "O3", "CO2", "PM2.5", "AQHI", "NO2_contrib",
        "O3_contrib", "PM2_5_contrib")
    ),
    expected_results = c(TRUE, FALSE, FALSE, TRUE, FALSE, FALSE)
  ),
  code = {
    testthat::expect_equal(
      sensor_data_is_from_git(col_names), expected_results
    )
  }
)


patrick::with_parameters_test_that(
  desc_stub = "Test sensor_data_manually_generated",
  .cases = tibble::tibble(
    col_names = list(
      c("date", "NO2", "NO", "CO2", "O3", "CO", "PM2_5"),
      c("date", "no2", "NO", "CO2", "O3", "CO", "PM2_5"),
      c("date", "NO2", "NO", "CO2", "extra", "O3", "CO", "PM2_5"),
      c("date", "NO2", "NO", "CO2", "O3", "CO"),
      c("date", "NO2", "PM2_5", "NO", "CO2", "O3", "CO")
    ),
    expected_results = c(TRUE, FALSE, FALSE, FALSE, FALSE)
  ),
  code = {
    testthat::expect_equal(
      sensor_data_manually_generated(col_names), expected_results
    )
  }
)