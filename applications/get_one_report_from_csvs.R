source("applications/report_automation.R")

# Start user adjustable parameters
outdoor_csv_dir <- "test_pipeline_outdoor3/October2025/MOD-00625.csv" # File inclusive
indoor_csv_dir <- "test_pipeline_indoor3/October2025/MOD-00617.csv" # File inclusive

start_date_char_outdoors <- "2025-10-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_outdoors <- "2025-10-31 23:45:00" # YYYY-MM-DD HH:MM:SS
start_date_char_indoors <- "2025-10-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_indoors <- "2025-10-31 23:45:00" # YYYY-MM-DD HH:MM:SS
outdoor_dates_in_utc <- FALSE
indoor_dates_in_utc <- FALSE

month_char <- "October"
year_int <- 2025
outdoor_sensor_id <- "MOD-00625"
indoor_sensor_id <- "MOD-00617"
location <- "Evelyne_Saller_Centre" # Matches name in sensor json
facility_photo_dir <- "facility_photos/EvelyneSaller_Photo.png"
# End user adjustable parameters

get_report_from_csvs(
  outdoor_csv_dir = outdoor_csv_dir,
  indoor_csv_dir = indoor_csv_dir,
  outdoor_processed_data_folder = "test_pipeline_outdoor3", # TODO: Change
  indoor_processed_data_folder = "test_pipeline_indoor3", # TODO: Change
  report_folder = "test_pipeline_reports3", # TODO: Change
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
