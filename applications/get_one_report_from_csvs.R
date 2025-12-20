source("applications/report_automation.R")

# Start user adjustable parameters
outdoor_csv_dir <- "Nov_unprocessed_data/2021_pred_2025_11_01.csv" # File inclusive
indoor_csv_dir <- "Nov_unprocessed_data/2020_pred_2025_11_01.csv" # File inclusive

start_date_char_outdoors <- "2025-11-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_outdoors <- "2025-11-30 23:45:00" # YYYY-MM-DD HH:MM:SS
start_date_char_indoors <- "2025-11-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_indoors <- "2025-11-30 23:45:00" # YYYY-MM-DD HH:MM:SS
outdoor_dates_in_utc <- FALSE
indoor_dates_in_utc <- FALSE

month_char <- "November"
year_int <- 2025
outdoor_sensor_id <- 2021
indoor_sensor_id <- 2020
location <- "West_Vancouver_Memorial_Library" # Matches name in sensor json
facility_photo_dir <- "facility_photos/WV_Library_Photo.png"
# End user adjustable parameters

get_report_from_csvs(
  outdoor_csv_dir = outdoor_csv_dir,
  indoor_csv_dir = indoor_csv_dir,
  outdoor_processed_data_folder = "outdoor_data_processed",
  indoor_processed_data_folder = "indoor_data_processed",
  report_folder = "facility_reports",
  start_date_char_outdoors = start_date_char_outdoors,
  end_date_char_outdoors = end_date_char_outdoors,
  start_date_char_indoors = start_date_char_indoors,
  end_date_char_indoors = end_date_char_indoors,
  outdoor_dates_in_utc = outdoor_dates_in_utc,
  indoor_dates_in_utc = indoor_dates_in_utc,
  month_char = month_char,
  year_int = year_int,
  outdoor_sensor_id = outdoor_sensor_id,
  indoor_sensor_id = indoor_sensor_id,
  location = location,
  facility_photo_dir = facility_photo_dir
)
