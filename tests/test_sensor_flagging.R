options(testthat.edition = 3)
testthat::context("Test sensor quality/flagging functions")
source("libraries/sensor_flagging_functions.R")


patrick::with_parameters_test_that(
  desc_stub = "Test get_sensor_uptime", code = {
    sensor_data_df <- readr::read_csv(csv_dir)
    sensor_data_df$date <- lubridate::force_tz(
      sensor_data_df$date, tzone = "Etc/GMT+8"
    )
    testthat::expect_equal(
      get_sensor_uptime(sensor_data_df, target_start, target_end),
      expected_uptime,
      tolerance = 1e-8
    )
  },
  csv_dir = c(
    "outdoor_data_processed/October2025/MOD-00631.csv",
    "tests/618_first300rows.csv",
    "indoor_data_processed/October2025/2029.csv",
    "outdoor_data_processed/October2025/2021.csv",
    "tests/631_endsNA.csv",
    "tests/631_allNA.csv"
  ),
  target_start = replicate(6, "2025-10-01 00:00:00"),
  target_end = replicate(6, "2025-10-31 23:45:00"),
  expected_uptime = c(2645 / 2917, 267 / 300, 2938 / 2945, 1, 170 / 2972, 0)
)


testthat::test_that(desc = "Test get_sensor_uptime w/o data", code = {
  sensor_data_df <- readr::read_csv("tests/empty.csv")

  # Test that the result is the correct value
  testthat::expect_equal(
    get_sensor_uptime(
      sensor_data_df, "2025-10-01 00:00:00", "2025-10-31 23:45:00"
    ),
    0
  )
})