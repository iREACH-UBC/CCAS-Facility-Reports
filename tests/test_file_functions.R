options(testthat.edition = 3)
testthat::context("Test file processing functions")
source("libraries/file_processing_functions.R")


patrick::with_parameters_test_that(
  desc_stub = "Test get_raw_git_urls",
  .cases = tibble::tibble(
    starts = c("2024-12-30", "2025-03-27"),
    stops = c("2025-01-04", "2025-03-27"),
    sensor_ids = c("2021", "MOD-00614"),
    expected_file_start_dates = list(
      c(
        "2024_12_28", "2024_12_29", "2024_12_30",
        "2024_12_31", "2025_01_01", "2025_01_02"),
      c("2025_03_25")
    ),
    expected_file_end_dates = list(
      c(
        "2024_12_30", "2024_12_31", "2025_01_01",
        "2025_01_02", "2025_01_03", "2025_01_04"),
      c("2025_03_27")
    )
  ),
  code = {
    expected_urls <- sprintf(
      paste0(
        "https://raw.githubusercontent.com/iREACH-UBC/CCAS_Dashboard/",
        "refs/heads/main/calibrated_data/%s/%s_calibrated_%s_to_%s.csv"
      ), sensor_ids, sensor_ids, expected_file_start_dates,
      expected_file_end_dates
    )
    testthat::expect_equal(
      get_raw_git_urls(
        starts, stops, sensor_ids
      ), expected_urls
    )
  }
)


patrick::with_parameters_test_that(
  desc_stub = "Test get_df_from_raw_git_urls",
  code = {
    raw_urls <- get_raw_git_urls(
      starts, stops, sensor_ids
    )
    testthat::expect_equal(
      get_df_from_raw_git_urls(raw_urls),
      as.data.frame(readr::read_csv(csv_dirs))
    )
  },
  starts = c("2025-10-27", "2025-09-30"),
  stops = c("2025-11-01", "2025-10-05"),
  sensor_ids = c("MOD-00631", "2029"),
  csv_dirs = c("tests/631_data.csv", "tests/2029_data.csv")
)


testthat::test_that(desc = "Test get_aqhi_column", code = {
  df <- readr::read_csv("tests/file_without_aqhi.csv", show_col_types = FALSE)
  expected_aqhi <- c( # Computed manually in Excel
    NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 3, NA, NA, 2, 2, 2, 2, 2, 2, 2, NA, NA, NA, 2, 2, 2, 2, 0, 2,
    2, 2, 1, 2, 2, 2
  )

  # Test that the result is the correct value
  testthat::expect_equal(get_aqhi_column(df), expected_aqhi)
})
