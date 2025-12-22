# Get reports for all sensors with outdoor and indoor data
# availble on Github within desired date range.
# Saves csvs of Git sensor data. If Git data is unavailable for
# some sensors, those reports are not generated. All reports
# are saved to facility_reports folder under corresponding month.

source("applications/report_automation.R")

# Start user adjustable parameters part 1
month_char <- "December"
year_int <- 2025
# End user adjustable parameters part 1

json_file_dir <- "sensor_data.json"
month_int <- match(month_char, month.name) # Do not change
month_dates <- get_month_start_end_dates(month_int, year_int)

# Start user adjustable parameters part 2
# Assumes same start/end dates for each sensor
start_date_char <- month_dates[["month_start_date"]]
end_date_char <- month_dates[["month_end_date"]]
# End user adjustable parameters part 2

get_all_reports_from_git_csvs(
  month_char = month_char,
  year_int = year_int,
  start_date_char = start_date_char,
  end_date_char = end_date_char,
  sensor_metadata = jsonlite::fromJSON(json_file_dir),
  overall_report_folder_name = "facility_reports",
  overall_photos_folder_name = "facility_photos",
  overall_outdoor_data_folder = "outdoor_data_processed",
  overall_indoor_data_folder = "indoor_data_processed"
)
