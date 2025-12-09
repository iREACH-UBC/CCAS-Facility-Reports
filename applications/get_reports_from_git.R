# Get reports for all sensors with outdoor and indoor data
# availble on Github within desired date range.
# Saves csvs of Git sensor data. If Git data is unavailable for
# some sensors, those reports are not generated. All reports
# are saved to facility_reports folder under corresponding month.

git_report_generator <- modules::use(
  "applications/automate_reports_using_git.R",
  reload = TRUE
)

# Start user adjustable parameters
# Assumes same start/end dates for each sensor
json_file_dir <- "sensor_data.json"
month_char <- "October"
month_int <- match(month_char, month.name) # Do not change
year_int <- 2025
month_dates <- get_month_start_end_dates(month_int, year_int)
start_date_char <- month_dates[["month_start_date"]]
end_date_char <- month_dates[["month_end_date"]]
# End user adjustable parameters

git_report_generator$get_all_reports_from_git_csvs(
  month_char = month_char,
  year_int = year_int,
  start_date_char = start_date_char,
  end_date_char = end_date_char,
  sensor_metadata = jsonlite::fromJSON(json_file_dir),
  overall_report_folder_name = "test_pipeline_reports3", # Change to facility_reports
  overall_photos_folder_name = "facility_photos",
  overall_outdoor_data_folder = "test_pipeline_outdoor3", # Change to outdoor_data_processed
  overall_indoor_data_folder = "test_pipeline_indoor3" # Change to indoor_data_processed
)
