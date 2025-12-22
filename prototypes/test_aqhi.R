# Test for AQHI prototype function. Function currently fails test
#  but unclear if this is a function error or test error (ex.
#  error in expected aqhi values).

testthat::test_that(desc = "Test get_aqhi_column", code = {
  df <- readr::read_csv(
    "tests/test_files/file_without_aqhi.csv", show_col_types = FALSE
  )
  expected_aqhi <- c( # Computed manually in Excel
    NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 3, NA, NA, 2, 2, 2, 2, 2, 2, 2, NA, NA, NA, 2, 2, 2, 2, 0, 2,
    2, 2, 1, 2, 2, 2
  )

  # Test that the result is the correct value
  testthat::expect_equal(get_aqhi_column(df), expected_aqhi)
})