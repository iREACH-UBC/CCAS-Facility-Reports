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
    "tests/test_files/618_first300rows.csv",
    "indoor_data_processed/October2025/2029.csv",
    "outdoor_data_processed/October2025/2021.csv",
    "tests/test_files/631_endsNA.csv",
    "tests/test_files/631_allNA.csv"
  ),
  target_start = replicate(6, "2025-10-01 00:00:00"),
  target_end = replicate(6, "2025-10-31 23:45:00"),
  expected_uptime = c(2645 / 2917, 267 / 300, 2938 / 2945, 1, 170 / 2972, 0)
)

testthat::test_that(desc = "Test get_sensor_uptime w/o data", code = {
  sensor_data_df <- readr::read_csv("tests/test_files/empty.csv")

  # Test that the result is the correct value
  testthat::expect_equal(
    get_sensor_uptime(
      sensor_data_df, "2025-10-01 00:00:00", "2025-10-31 23:45:00"
    ),
    0
  )
})


patrick::with_parameters_test_that(
  desc_stub = "Test get_actual_num_times_per_date",
  .cases = tibble::tibble(
    url = c(
      "tests/test_files/631_allNA.csv",
      "tests/test_files/631_endsNA.csv",
      "tests/test_files/sample_data.csv"
    ),
    start_dates = c("2025-10-20 12:33:00", "2025-10-22 23:45:00", "2025-10-01 00:00:00"),
    end_dates = c("2025-10-28 00:00:00", "2025-10-29 12:01:00", "2025-10-31 23:45:00"),
    expected_counts = list(
      c(0, 0, 0, 0, 0, 0, 0, 0, 0),
      c(0, 0, 0, 0, 0, 49, 96, 25),
      c(
        3, 4, 2, 4, 1, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
      )
    )
  ),
  code = {
    expected_dates <- as.character(seq(
      from = as.Date(start_dates), to = as.Date(end_dates), by = "day"
    ))
    expected_df <- data.frame(date = expected_dates, count = expected_counts)
    testthat::expect_equal(
      get_actual_num_times_per_date(
        readr::read_csv(url), start_dates, end_dates
      ), expected_df
    )
  }
)