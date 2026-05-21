source("applications/report_automation.R")

# Start user adjustable parameters
input_data_folder_dir <- "C:\\Users\\jaspe\\OneDrive\\Documents\\lcs-calibrated-data\\monthly"
start_date <- "2026-04-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date <- "2026-04-30 23:45:00" # YYYY-MM-DD HH:MM:SS
ramps_in_utc <- TRUE
qaqs_in_utc <- TRUE
month_name <- "April"
year <- 2026
# End user adjustable parameters

get_reports_from_manual_csvs(
  unprocessed_data_folder_dir = input_data_folder_dir,
  sensor_metadata = jsonlite::fromJSON("sensor_data.json"),
  start_date_char = start_date,
  end_date_char = end_date,
  ramps_in_utc = ramps_in_utc,
  qaqs_in_utc = qaqs_in_utc,
  outdoor_processed_data_folder = "outdoor_data_processed",
  indoor_processed_data_folder = "indoor_data_processed",
  report_folder = "facility_reports",
  month_char = month_name,
  year_int = year,
  overall_photos_folder_name = "facility_photos"
)