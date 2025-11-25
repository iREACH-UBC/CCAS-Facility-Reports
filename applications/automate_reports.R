source("applications/get_sensor_data.R")
source("applications/generate_report.R")

# Get metadata used in processing
# Assumes same start/end dates for each sensor
# Start user adjustable parameters
json_file_dir <- "sensor_data.json"
month_char <- "October"
month_int <- match(month_char, month.name) # Do not change
year_int <- 2025
month_dates <- get_month_start_end_dates(month_int, year_int)
start_date_char <- month_dates[["month_start_date"]]
end_date_char <- month_dates[["month_end_date"]]
# End user adjustable parameters

print("Got metadata")

sensor_data <- jsonlite::fromJSON(json_file_dir)
includes_time_change <- data_includes_time_change(
  month_int, start_date_char, end_date_char, year_int
)

print("Got sensor data")

sensor_dfs <- get_all_processed_sensor_dfs(
  sensor_data, start_date_char, end_date_char, includes_time_change,
  "test_pipeline_outdoor", "test_pipeline_indoor"
)

generate_all_reports(
  "test_reports", "facility_photos", "test_pipeline_outdoor",
  "test_pipeline_indoor", sensor_data, year_int,
  month_char, includes_time_change,
  sensor_dfs[["outdoor_sensor_data"]],
  sensor_dfs[["indoor_sensor_data"]]
)
