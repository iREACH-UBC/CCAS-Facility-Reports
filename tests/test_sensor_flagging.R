options(testthat.edition = 3)
testthat::context("Test sensor quality/flagging functions")
source("libraries/sensor_flagging_functions.R")


patrick::with_parameters_test_that(
  desc_stub = "Test get_actual_num_times_per_dataset", code = {
    sensor_data_df <- readr::read_csv(csv_dir)
    testthat::expect_equal(
      get_actual_num_times_per_dataset(sensor_data_df),
      expected_times_per_dataset
    )
  },
  csv_dir = c(
    "outdoor_data_processed/October2025/MOD-00631.csv",
    "tests/test_files/618_first300rows.csv",
    "indoor_data_processed/October2025/2029.csv",
    "outdoor_data_processed/October2025/2021.csv",
    "tests/test_files/631_endsNA.csv",
    "tests/test_files/631_allNA.csv",
    "tests/test_files/one_day_NA.csv"
  ),
  expected_times_per_dataset = c(2645, 267, 2938, 2944, 170, 0, 0)
)


patrick::with_parameters_test_that(
  desc_stub = "Test get_expected_num_times_per_dataset", code = {
    testthat::expect_equal(
      get_expected_num_times_per_dataset(target_start, target_end),
      expected_num_times
    )
  },
  target_start = c("2025-10-01 00:00:00", "2025-11-01 00:01:00",
    "2024-06-15 03:12:00", "2025-12-18 00:00:00",
    "2025-03-01 00:00:00", "2025-05-22 23:38:00",
    "2025-01-17 19:32:00", "2026-07-10 00:00:00"
  ),
  target_end = c("2025-10-01 23:45:00", "2025-11-03 22:22:00",
    "2024-06-15 15:21:00", "2025-12-18 00:00:00",
    "2025-03-31 23:59:00", "2025-05-31 05:05:00",
    "2025-01-17 19:33:00", "2026-07-10 2:00:00"
  ),
  expected_num_times = c(96, 282, 49, 0, 2976, 790, 1, 9)
)


testthat::test_that(
  desc = "Test get_expected_num_times_per_dataset error", code =
  {
    testthat::expect_error(
      get_expected_num_times_per_dataset(
        "2025-02-03 00:00:00", "2025-02-29 00:15:00"
      )
    )
  }
)


patrick::with_parameters_test_that(
  desc_stub = "Test remove_days_with_low_uptime", code = {
    input_sensor_data_df <- readr::read_csv(input_csv_dir)
    # Include column types to avoid tibble's default character type
    # Relevant only when reading empty dataframes
    output_sensor_data_df <- readr::read_csv(
      output_csv_dir, col_types = readr::cols(
        date  = readr::col_datetime(),
        CO    = readr::col_double(),
        NO2   = readr::col_double(),
        NO    = readr::col_double(),
        O3    = readr::col_double(),
        PM2_5 = readr::col_double(),
        CO2 = readr::col_double(),
        AQHI = readr::col_integer()
      )
    )
    # Convert to tibbles to ensure consistent types
    testthat::expect_equal(
      tibble::as_tibble(remove_days_with_low_uptime(
        input_sensor_data_df, target_start, target_end,
        uptime_threshold
      )),
      tibble::as_tibble(output_sensor_data_df)
    )
  },
  input_csv_dir = c(
    "outdoor_data_processed/October2025/2021.csv",
    "tests/test_files/sample_data.csv",
    "tests/test_files/sample_data.csv",
    "tests/test_files/sample_data.csv"
  ),
  target_start = c("2025-10-01 00:00:00", "2025-10-01 01:00:00",
    "2025-10-01 00:00:00", "2025-10-01 00:30:00"
  ),
  target_end = c("2025-10-31 23:45:00", "2025-10-30 22:22:00",
    "2025-10-31 23:45:00", "2025-10-29 23:45:00"
  ),
  uptime_threshold = c(0.5, 0.4, 0.02, 0.05),
  output_csv_dir = c(
    "outdoor_data_processed/October2025/2021.csv",
    "tests/test_files/empty.csv",
    "tests/test_files/sample_data_mod02.csv",
    "tests/test_files/sample_data_mod05.csv"
  )
)
