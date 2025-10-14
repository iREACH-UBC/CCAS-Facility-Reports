# Start and stop inclusive
# Dates in "YYYY-MM-DD" format
# sensor_id can be a char (ex. "2021") or number (ex. 2021)
get_file_urls <- function(file_end_date_start, file_end_date_stop, sensor_id) {
  start_date <- as.Date(file_end_date_start)
  stop_date <- as.Date(file_end_date_stop)

  file_end_dates_numeric <- as.numeric(start_date):as.numeric(stop_date)
  file_start_dates_numeric <- file_end_dates_numeric - 2

  end_dates <- as.Date(file_end_dates_numeric, origin = "1970-01-01")
  start_dates <- as.Date(file_start_dates_numeric, origin = "1970-01-01")

  end_dates_char <- as.character(gsub("-", "_", end_dates))
  start_dates_char <- as.character(gsub("-", "_", start_dates))

  return(sprintf(paste0(
  "https://raw.githubusercontent.com/iREACH-UBC/CCAS_Dashboard/refs/heads/",
  "main/calibrated_data/%s/%s_calibrated_%s_to_%s.csv"),
  sensor_id, sensor_id, start_dates_char, end_dates_char))
}

