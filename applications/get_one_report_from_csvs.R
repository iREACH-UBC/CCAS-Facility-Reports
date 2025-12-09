sensor_data_processor <- modules::use(
  "libraries/preprocess_sensor_data.R", reload = TRUE
)
file_processor <- modules::use(
  "libraries/file_processing_functions.R", reload = TRUE
)
report_generator <- modules::use("libraries/generate_report.R", reload = TRUE)

# Start user adjustable parameters
outdoor_csv_dir <- "CHANGETHIS" # TODO- get a sample csv
indoor_csv_dir <- "CHANGETHIS" # TODO- get a sample csv
outdoor_csv_from_git <- TRUE
indoor_csv_from_git <- TRUE
outdoor_csv_data_is_processed <- TRUE
indoor_csv_data_is_processed <- TRUE


start_date_char_outdoors <- "2025-10-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_outdoors <- "2025-10-31 23:45:00" # YYYY-MM-DD HH:MM:SS
start_date_char_indoors <- "2025-10-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_indoors <- "2025-10-31 23:45:00" # YYYY-MM-DD HH:MM:SS
outdoor_dates_in_utc <- TRUE
indoor_dates_in_utc <- TRUE

month_char <- "October"
month_int <- match(month_char, month.name) # Do not change
year_int <- 2025
outdoor_sensor_id <- 2040
indoor_sensor_id <- 2044
location <- "Gillies_Bay_Public_Library" # Matches name in sensor json
facility_photo_dir <- "facility_photos/GilliesBay_Photo.png"
# End user adjustable parameters

month_abbrev <- month.abb[month_int]

# Read data from csvs, process data if needed
processed_outdoor_df <- sensor_data_processor$get_processed_df_from_csv(
  csv_dir = outdoor_csv_dir,
  csv_from_git = outdoor_csv_from_git,
  csv_data_is_processed = outdoor_csv_data_is_processed,
  start_date_char = start_date_char_outdoors,
  end_date_char = end_date_char_outdoors,
  dates_in_utc = outdoor_dates_in_utc,
  month_int = month_int,
  year_int = year_int
)
processed_indoor_df <- sensor_data_processor$get_processed_df_from_csv(
  csv_dir = indoor_csv_dir,
  csv_from_git = indoor_csv_from_git,
  csv_data_is_processed = indoor_csv_data_is_processed,
  start_date_char = start_date_char_indoors,
  end_date_char = end_date_char_indoors,
  dates_in_utc = indoor_dates_in_utc,
  month_int = month_int,
  year_int = year_int
)

# Save outdoor and indoor data to csvs with standardized name conventions
file_processor$save_sensor_data_csv(
  month_char = month_char,
  year_int = year_int,
  location_folder = "test_pipeline_outdoor3",
  processed_sensor_data_df = processed_outdoor_df,
  timezone = lubridate::tz(processed_outdoor_df$date),
  sensor_id = outdoor_sensor_id
)
file_processor$save_sensor_data_csv(
  month_char = month_char,
  year_int = year_int,
  location_folder = "test_pipeline_indoor3",
  processed_sensor_data_df = processed_indoor_df,
  timezone = lubridate::tz(processed_indoor_df$date),
  sensor_id = indoor_sensor_id
)

# Generate report
report_generator$generate_one_report(
  year_int = year_int,
  month_char = month_char,
  start_date_char_outdoors = start_date_char_outdoors,
  start_date_char_indoors = start_date_char_indoors,
  end_date_char_outdoors = end_date_char_outdoors,
  end_date_char_indoors = end_date_char_indoors,
  facility_location_char = chartr("_", " ", location),
  facility_photo_directory = facility_photo_dir, # File inclusive
  outdoor_file_df = processed_outdoor_df,
  indoor_file_df = processed_indoor_df,
  output_file_name = sprintf(
    "Report_%s_%s%s.pdf", gsub("_", "", location), month_abbrev, year_int
  ),
  output_file_directory = file.path(
    "test_pipeline_reports3", sprintf("%s%s_reports", month_abbrev, year_int)
  ) # TODO: CHANGE
)