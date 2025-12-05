
options(testthat.edition = 3)
library(testthat)
library(patrick)
context("Test time-related functions")
source("libraries/time_processing_functions.R")


# 6 tests
patrick::with_parameters_test_that(
  desc_stub = "Test get_month_start_end_dates", code = {
    expect_equal(
      get_month_start_end_dates(month, year),
      list(
        month_start_date = expected_start,
        month_end_date   = expected_end
      )
    )
  },
  month = c(2, 2, 5, 9, 10, 12),
  year  = c(2024, 2025, 2020, 2026, 2027, 2026),
  expected_start = c(
    "2024-02-01 00:00:00", "2025-02-01 00:00:00",
    "2020-05-01 00:00:00", "2026-09-01 00:00:00",
    "2027-10-01 00:00:00", "2026-12-01 00:00:00"
  ),
  expected_end = c(
    "2024-02-29 23:45:00", "2025-02-28 23:45:00",
    "2020-05-31 23:45:00", "2026-09-30 23:45:00",
    "2027-10-31 23:45:00", "2026-12-31 23:45:00"
  )
)


# 6 tests
patrick::with_parameters_test_that(
  desc_stub = "Test shift_timezones_at_time_change valid cases",
  .cases = tibble::tibble(
    index_b4_change = c(1, 2, 3, 3, 4, 4),
    timezone_b4 = c(
      "UTC", "Etc/GMT+8", "Etc/GMT+7", "Etc/GMT+7", "Etc/GMT+8", "UTC"
    ),
    timezone_after = c(
      "Etc/GMT+8", "US/Pacific", "Etc/GMT+8", "UTC", "Etc/GMT+7", "UTC"
    ),
    final_timezone = c(
      "UTC", "Etc/GMT+8", "Etc/GMT+7", "Etc/GMT+8", "Etc/GMT+7", "Etc/GMT+8"
    ),
    dates_repeated = replicate(6, as.POSIXct(c(
      "2025-01-01 00:00:00", "2025-01-01 10:15:00",
      "2025-01-01 23:59:00", "2025-01-07 04:35:00",
      "2025-01-31 23:30:00"
    ), tz = "UTC"), simplify = FALSE), # Change if you add/delete a case
    dates_expected = list(
      as.POSIXct(c(
        "2025-01-01 00:00:00", "2025-01-01 18:15:00",
        "2025-01-02 07:59:00", "2025-01-07 12:35:00",
        "2025-02-01 07:30:00"
      ), tz = "UTC"),
      as.POSIXct(c(
        "2025-01-01 00:00:00", "2025-01-01 10:15:00",
        "2025-01-01 23:59:00", "2025-01-07 04:35:00",
        "2025-01-31 23:30:00"
      ), tz = "Etc/GMT+8"),
      as.POSIXct(c(
        "2025-01-01 00:00:00", "2025-01-01 10:15:00",
        "2025-01-01 23:59:00", "2025-01-07 05:35:00",
        "2025-02-01 00:30:00"
      ), tz = "Etc/GMT+7"),
      as.POSIXct(c(
        "2024-12-31 23:00:00", "2025-01-01 09:15:00",
        "2025-01-01 22:59:00", "2025-01-06 20:35:00",
        "2025-01-31 15:30:00"
      ), tz = "Etc/GMT+8"),
      as.POSIXct(c(
        "2025-01-01 01:00:00", "2025-01-01 11:15:00",
        "2025-01-02 00:59:00", "2025-01-07 05:35:00",
        "2025-01-31 23:30:00"
      ), tz = "Etc/GMT+7"),
      as.POSIXct(c(
        "2024-12-31 16:00:00", "2025-01-01 02:15:00",
        "2025-01-01 15:59:00", "2025-01-06 20:35:00",
        "2025-01-31 15:30:00"
      ), tz = "Etc/GMT+8")
    )
  ),
  code = {
    expect_equal(
      shift_timezones_at_time_change(
        dates_repeated, index_b4_change,
        timezone_b4, timezone_after, final_timezone
      ),
      dates_expected
    )
  }
)


# 2 tests
patrick::with_parameters_test_that(
  desc_stub = "Test shift_timezones_at_time_change invalid cases",
  .cases = tibble::tibble(
    index_b4_change = c(0, 5),
    timezone_b4 = c("UTC", "Etc/GMT+8"),
    timezone_after = c("Etc/GMT+8", "US/Pacific"),
    final_timezone = c("UTC", "Etc/GMT+8"),
    dates_repeated = replicate(2, as.POSIXct(c(
      "2025-01-01 00:00:00", "2025-01-01 10:15:00",
      "2025-01-01 23:59:00", "2025-01-07 04:35:00",
      "2025-01-31 23:30:00"
    ), tz = "UTC"), simplify = FALSE), # Change if you add/delete a case
  ),
  code = {
    expect_error(
      shift_timezones_at_time_change(
        dates_repeated, index_b4_change,
        timezone_b4, timezone_after, final_timezone
      )
    )
  }
)


# 10 tests
testthat::test_that(desc = "Test set_timezone_from_month", code = {
  times_nov_before_change <- as.POSIXct(c(
    "2025-11-01 00:00:00", "2025-11-01 10:30:00", "2025-11-02 00:47:00"
  ), tz = "UTC")
  expected_nov_before_change <- as.POSIXct(c(
    "2025-11-01 00:00:00", "2025-11-01 10:30:00", "2025-11-02 00:47:00"
  ), tz = "Etc/GMT+8") - lubridate::hours(1)

  times_nov_after_change <- as.POSIXct(c(
    "2025-11-02 01:30:00", "2025-11-02 02:00:00",
    "2025-11-02 03:01:00", "2025-11-07 00:00:00"
  ), tz = "UTC")
  expected_nov_after_change <- as.POSIXct(c(
    "2025-11-02 01:30:00", "2025-11-02 02:00:00",
    "2025-11-02 03:01:00", "2025-11-07 00:00:00"
  ), tz = "Etc/GMT+8")

  times_mar_before_change <- as.POSIXct(c(
    "2025-03-01 00:00:00", "2025-03-04 02:00:00",
    "2025-03-05 03:01:00", "2025-03-08 23:00:00"
  ), tz = "UTC")
  expected_mar_before_change <- as.POSIXct(c(
    "2025-03-01 00:00:00", "2025-03-04 02:00:00",
    "2025-03-05 03:01:00", "2025-03-08 23:00:00"
  ), tz = "Etc/GMT+8")

  times_mar_after_change <- as.POSIXct(c(
    "2025-03-09 03:00:00", "2025-03-14 02:00:00",
    "2025-03-15 03:01:00", "2025-03-31 23:00:00"
  ), tz = "UTC")
  expected_mar_after_change <- as.POSIXct(c(
    "2025-03-09 03:00:00", "2025-03-14 02:00:00",
    "2025-03-15 03:01:00", "2025-03-31 23:00:00"
  ), tz = "Etc/GMT+8") - lubridate::hours(1)

  times_nov_time_change_ramp <- as.POSIXct(c(
    "2025-11-02 00:30:00",
    "2025-11-02 00:45:00",
    "2025-11-02 01:00:00",
    "2025-11-02 01:15:00",
    "2025-11-02 01:30:00",
    "2025-11-02 01:45:00",
    "2025-11-02 01:00:00",
    "2025-11-02 01:15:00",
    "2025-11-02 01:30:00",
    "2025-11-02 01:45:00",
    "2025-11-02 02:00:00",
    "2025-11-02 02:15:00",
    "2025-11-02 02:30:00"
  ), tz = "UTC")
  expected_nov_time_change_ramp <- as.POSIXct(c(
    "2025-11-01 23:30:00",
    "2025-11-01 23:45:00",
    "2025-11-02 00:00:00",
    "2025-11-02 00:15:00",
    "2025-11-02 00:30:00",
    "2025-11-02 00:45:00",
    "2025-11-02 01:00:00",
    "2025-11-02 01:15:00",
    "2025-11-02 01:30:00",
    "2025-11-02 01:45:00",
    "2025-11-02 02:00:00",
    "2025-11-02 02:15:00",
    "2025-11-02 02:30:00"
  ), tz = "Etc/GMT+8")

  times_nov_time_change_qaq <- as.POSIXct(c(
    "2025-11-02 00:30:00",
    "2025-11-02 00:45:00",
    "2025-11-02 01:00:00",
    "2025-11-02 01:15:00",
    "2025-11-02 01:30:00",
    "2025-11-02 01:45:00",
    "2025-11-02 02:00:00",
    "2025-11-02 02:15:00",
    "2025-11-02 02:30:00"
  ), tz = "UTC")
  expected_nov_time_change_qaq <- as.POSIXct(c(
    "2025-11-01 23:30:00",
    "2025-11-01 23:45:00",
    "2025-11-02 01:00:00",
    "2025-11-02 01:15:00",
    "2025-11-02 01:30:00",
    "2025-11-02 01:45:00",
    "2025-11-02 02:00:00",
    "2025-11-02 02:15:00",
    "2025-11-02 02:30:00"
  ), tz = "Etc/GMT+8")

  times_mar_time_change <- as.POSIXct(c(
    "2025-03-09 01:15:00",
    "2025-03-09 01:30:00",
    "2025-03-09 01:45:00",
    "2025-03-09 03:00:00",
    "2025-03-09 03:15:00",
    "2025-03-09 03:30:00"
  ), tz = "UTC")
  expected_mar_time_change <- as.POSIXct(c(
    "2025-03-09 01:15:00",
    "2025-03-09 01:30:00",
    "2025-03-09 01:45:00",
    "2025-03-09 02:00:00",
    "2025-03-09 02:15:00",
    "2025-03-09 02:30:00"
  ), tz = "Etc/GMT+8")

  times_mar_time_change_utc <- as.POSIXct(c(
    "2025-03-09 09:15:00",
    "2025-03-09 09:30:00",
    "2025-03-09 09:45:00",
    "2025-03-09 10:00:00",
    "2025-03-09 10:15:00",
    "2025-03-09 10:30:00"
  ), tz = "UTC")
  expected_mar_time_change_utc <- as.POSIXct(c(
    "2025-03-09 01:15:00",
    "2025-03-09 01:30:00",
    "2025-03-09 01:45:00",
    "2025-03-09 02:00:00",
    "2025-03-09 02:15:00",
    "2025-03-09 02:30:00"
  ), tz = "Etc/GMT+8")

  times_sept <- as.POSIXct(c(
    "2025-09-01 00:00:00", "2025-09-01 10:30:00", "2025-09-02 00:47:00"
  ), tz = "UTC")
  expected_sept <- as.POSIXct(c(
    "2025-09-01 00:00:00", "2025-09-01 10:30:00", "2025-09-02 00:47:00"
  ), tz = "US/Pacific")

  times_sept_utc <- as.POSIXct(c(
    "2025-09-02 00:00:00", "2025-09-02 10:30:00", "2025-09-03 00:47:00"
  ), tz = "UTC")
  expected_sept_utc <- as.POSIXct(c(
    "2025-09-01 17:00:00", "2025-09-02 03:30:00", "2025-09-02 17:47:00"
  ), tz = "US/Pacific")

  # Test that the result is the correct value
  expect_equal(expected_nov_before_change, set_timezone_from_month(
    times_nov_before_change, 11, 2025, FALSE
  ))
  expect_equal(expected_nov_after_change, set_timezone_from_month(
    times_nov_after_change, 11, 2025, FALSE
  ))
  expect_equal(expected_mar_before_change, set_timezone_from_month(
    times_mar_before_change, 3, 2025, FALSE
  ))
  expect_equal(expected_mar_after_change, set_timezone_from_month(
    times_mar_after_change, 3, 2025, FALSE
  ))
  expect_equal(expected_nov_time_change_ramp, set_timezone_from_month(
    times_nov_time_change_ramp, 11, 2025, FALSE
  ))
  expect_equal(expected_nov_time_change_qaq, set_timezone_from_month(
    times_nov_time_change_qaq, 11, 2025, FALSE
  ))
  expect_equal(expected_mar_time_change, set_timezone_from_month(
    times_mar_time_change, 3, 2025, FALSE
  ))
  expect_equal(expected_mar_time_change_utc, set_timezone_from_month(
    times_mar_time_change_utc, 3, 2025, TRUE
  ))
  expect_equal(expected_sept, set_timezone_from_month(
    times_sept, 9, 2025, FALSE
  ))
  expect_equal(expected_sept_utc, set_timezone_from_month(
    times_sept_utc, 9, 2025, TRUE
  ))
})


patrick::with_parameters_test_that(
  desc_stub = "Test remove_out_of_range_data",
  .cases = tibble::tibble(
    sample_dfs = replicate(7, data.frame(
      date = as.POSIXct(c(
        "2024-12-31 23:00:00", "2025-01-01 00:00:00", "2025-01-05 14:30:00",
        "2025-01-21 05:00:00", "2025-02-01 00:00:00", "2025-11-19 09:03:00",
        "2025-12-31 23:45:00", "2026-01-01 03:00:00"
      ), tz = "UTC"),
      sample_col1 = c(1, 2, 3, 4, 5, 6, 7, 8),
      sample_col2 = c(10, 20, 30, 40, 50, 60, 70, 80)
    ), simplify = FALSE),
    start_dates = c(
      "2024-12-31 23:00:00", "2026-01-01 03:00:00", "2025-01-05 14:31:00",
      "2024-12-31", "2023-12-31 22:00:00", "2024-11-30 22:00:00",
      "2025-11-05 22:00:00"
    ),
    end_dates = c(
      "2026-01-01 03:00:00", "2026-01-01 13:00:00", "2025-01-11",
      "2026-01-01 01:00:00", "2024-12-31 22:00:00", "2025-03-21 22:00:00",
      "2026-11-30 22:00:00"
    ),
    expected_dates = list(
      as.POSIXct(c(
        "2024-12-31 23:00:00", "2025-01-01 00:00:00", "2025-01-05 14:30:00",
        "2025-01-21 05:00:00", "2025-02-01 00:00:00", "2025-11-19 09:03:00",
        "2025-12-31 23:45:00", "2026-01-01 03:00:00"
      ), tz = "UTC"),
      as.POSIXct(c("2026-01-01 03:00:00"), tz = "UTC"),
      c(as.POSIXct(character(), tz = "UTC")),
      as.POSIXct(c(
        "2024-12-31 23:00:00", "2025-01-01 00:00:00", "2025-01-05 14:30:00",
        "2025-01-21 05:00:00", "2025-02-01 00:00:00", "2025-11-19 09:03:00",
        "2025-12-31 23:45:00"
      ), tz = "UTC"),
      c(as.POSIXct(character(), tz = "UTC")),
      as.POSIXct(c(
        "2024-12-31 23:00:00", "2025-01-01 00:00:00", "2025-01-05 14:30:00",
        "2025-01-21 05:00:00", "2025-02-01 00:00:00"
      ), tz = "UTC"),
      as.POSIXct(c(
        "2025-11-19 09:03:00", "2025-12-31 23:45:00", "2026-01-01 03:00:00"
      ), tz = "UTC")
    )
  ),
  code = {
    expect_equal(
      remove_out_of_range_data(
        sample_dfs, start_dates, end_dates
      )$date, expected_dates
    )
  }
)