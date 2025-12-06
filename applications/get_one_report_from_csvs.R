# TODO- finsih script!!!

sensor_data_processor <- modules::use("libraries/preprocess_sensor_data.R")
file_processor <- modules::use("libraries/file_processing_functions.R")
report_generator <- modules::use("libraries/generate_report.R")

# Start user adjustable parameters
outdoor_csv_dir <- "CHANGETHIS"
indoor_csv_dir <- "CHANGETHIS"
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
# End user adjustable parameters

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
file_processor$save_sensor_data_csv(
  month_char = month_char,
  year_int = year_int,
  location_folder = test_pipeline_outdoor3,
  processed_sensor_data_df = processed_outdoor_df,
  timezone = lubridate::tz(processed_outdoor_df$date),
  sensor_id = outdoor_sensor_id
)
report_generator$generate_one_report(
  year_int,
  month_char,
  start_date_char_outdoors,
  start_date_char_indoors,
  end_date_char_outdoors,
  end_date_char_indoors,
  facility_location_char,
  facility_photo_directory, # File inclusive
  outdoor_file_df,
  indoor_file_df,
  output_file_name,
  output_file_directory # File exclusive
)