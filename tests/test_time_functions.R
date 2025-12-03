
options(testthat.edition = 3)
library(testthat)
library(patrick)
context("Test time-related functions")
source("libraries/time_processing_functions.R")

# test_that(desc = "Test get_month_start_end_dates", code = {
#   months <- c(2, 2, 5, 9, 10, 12)
#   years <- c(2024, 2025, 2020, 2026, 2027, 2026)
#   expected_starts <- c(
#     "2024-02-01 00:00:00", "2025-02-01 00:00:00",
#     "2020-05-01 00:00:00", "2026-09-01 00:00:00",
#     "2027-10-01 00:00:00", "2026-12-01 00:00:00"
#   )
#   expected_ends <- c(
#     "2024-02-29 23:45:00", "2025-02-28 23:45:00",
#     "2020-05-30 23:45:00", "2026-09-30 23:45:00",
#     "2027-10-31 23:45:00", "2026-12-31 23:45:00"
#   )
#   expect_equal(1, 1)

#   for (i in seq_along(months)) {
#     expect_equal(get_month_start_end_dates(months[[i]], years[[i]]),
#       list("month_start_date" = expected_starts[[i]],
#         "month_end_date" = expected_ends[[i]]
#       )
#     )
#   }
# })

with_parameters_test_that(
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
    "2020-05-30 23:45:00", "2026-09-30 23:45:00",
    "2027-10-31 23:45:00", "2026-12-31 23:45:00"
  )
)


test_that(desc = "Test set_timezone_from_month", code = {
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