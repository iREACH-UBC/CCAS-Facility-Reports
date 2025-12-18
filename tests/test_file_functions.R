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
      as.data.frame(readr::read_csv(csv_dirs, show_col_types = FALSE))
    )
  },
  starts = c("2025-10-27", "2025-09-30"),
  stops = c("2025-11-01", "2025-10-05"),
  sensor_ids = c("MOD-00631", "2029"),
  csv_dirs = c("tests/test_files/631_data.csv", "tests/test_files/2029_data.csv")
)


# testthat::test_that(desc = "Test get_aqhi_column", code = {
#   df <- readr::read_csv("tests/test_files/file_without_aqhi.csv", show_col_types = FALSE)
#   expected_aqhi <- c( # Computed manually in Excel
#     NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
#     2, 2, 2, 2, 2, 3, NA, NA, 2, 2, 2, 2, 2, 2, 2, NA, NA, NA, 2, 2, 2, 2, 0, 2,
#     2, 2, 1, 2, 2, 2
#   )

#   # Test that the result is the correct value
#   testthat::expect_equal(get_aqhi_column(df), expected_aqhi)
# })


testthat::test_that(desc = "Test separate_df_by_day", code = {
  df <- readr::read_csv(
    "tests/test_files/simple_df.csv", show_col_types = FALSE
  )
  start_date <- "2025-10-01"
  end_date <- "2025-10-31"
  empty_df <- df[0, ]
  timezone <- lubridate::tz(df$date)
  expected_list <- list(
    "2025-10-01" = data.frame(
      date = as.POSIXct(
        c("2025-10-01 01:12:00", "2025-10-01 02:27:00", "2025-10-01 02:42:00"), tz = timezone
      ),
      col2 = c(3, 7, 52),
      col3 = c(3, 2, 0)
    ),
    "2025-10-02" = data.frame(
      date = as.POSIXct(c(
        "2025-10-02 00:57:00", "2025-10-02 01:12:00", "2025-10-02 01:27:00", "2025-10-02 01:42:00",
        "2025-10-02 01:57:00", "2025-10-02 02:12:00", "2025-10-02 02:27:00", "2025-10-02 02:42:00"
      ), tz = timezone),
      col2 = c(NA, NA, NA, NA, 1, 3, 6, 227),
      col3 = c(NA, NA, NA, NA, 29, 7, 12, 24)
    ),
    "2025-10-03" = data.frame(
      date = as.POSIXct(c("2025-10-03 02:57:00", "2025-10-03 03:12:00"), tz = timezone),
      col2 = c(3, 46),
      col3 = c(22, 10)
    ),
    "2025-10-04" = data.frame(
      date = as.POSIXct(c(
        "2025-10-04 03:27:00", "2025-10-04 03:42:00",
        "2025-10-04 03:57:00", "2025-10-04 04:12:00"
      ), tz = timezone),
      col2 = c(3, 2, 19, 333),
      col3 = c(2, 9, 5, 2)
    ),
    "2025-10-05" = data.frame(
      date = as.POSIXct(c("2025-10-05 04:27:00"), tz = timezone),
      col2 = c(2),
      col3 = c(8)
    ),
    "2025-10-06" = empty_df,
    "2025-10-07" = data.frame(
      date = as.POSIXct(c("2025-10-07 04:42:00", "2025-10-07 04:57:00"), tz = timezone),
      col2 = c(427, 237),
      col3 = c(2, 5)
    ),
    "2025-10-08" = empty_df, "2025-10-09" = empty_df, "2025-10-10" = empty_df,
    "2025-10-11" = data.frame(
      date = as.POSIXct(c("2025-10-11 05:12:00", "2025-10-11 05:27:00"), tz = timezone),
      col2 = c(20, 2),
      col3 = c(1, 4)
    ),
    "2025-10-12" = empty_df, "2025-10-13" = empty_df, "2025-10-14" = empty_df,
    "2025-10-15" = empty_df, "2025-10-16" = empty_df, "2025-10-17" = empty_df,
    "2025-10-18" = empty_df, "2025-10-19" = empty_df, "2025-10-20" = empty_df,
    "2025-10-21" = data.frame(
      date = as.POSIXct(c("2025-10-21 05:42:00"), tz = timezone),
      col2 = c(83),
      col3 = c(1)
    ),
    "2025-10-22" = data.frame(
      date = as.POSIXct(c("2025-10-22 05:57:00"), tz = timezone),
      col2 = c(6),
      col3 = c(3)
    ),
    "2025-10-23" = empty_df, "2025-10-24" = empty_df, "2025-10-25" = empty_df,
    "2025-10-26" = empty_df, "2025-10-27" = empty_df, "2025-10-28" = empty_df,
    "2025-10-29" = data.frame(
      date = as.POSIXct(c("2025-10-29 06:12:00"), tz = timezone),
      col2 = c(as.numeric(NA)), # Set to numeric to preserve tibble's column type
      col3 = c(as.numeric(NA)) # Set to numeric to preserve tibble's column type
    ),
    "2025-10-30" = empty_df, "2025-10-31" = empty_df
  )
  testthat::expect_equal( # Convert to tibble to ensure same datatype is compared
    lapply(separate_df_by_day(df, start_date, end_date), tibble::as_tibble),
    lapply(expected_list, tibble::as_tibble)
  )
})
