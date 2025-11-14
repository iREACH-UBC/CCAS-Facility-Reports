# A script to generate October csvs. To be changed for Nov
source("libraries/helper_functions.R")

sensor_metadata <- extract_sensor_data_from_json(
  "sensor_data.json"
)
sensor_data <- sensor_metadata[["sensor_data"]]

for (location in names(sensor_data)[12:length(names(sensor_data))]) {
  location_data <- sensor_data[[location]]

  # Use if dates differ from full month
  outdoor_raw_urls <- get_file_urls(
    start_date = location_data[["outdoor_data_start_date"]],
    stop_date = location_data[["outdoor_data_end_date"]],
    sensor_id = location_data[["outdoor_sensor_ID"]]
  )
  indoor_raw_urls <- get_file_urls(
    start_date = location_data[["indoor_data_start_date"]],
    stop_date = location_data[["indoor_data_end_date"]],
    sensor_id = location_data[["indoor_sensor_ID"]]
  )

  # # Use if dates are full month for all sensors
  # month_dates <- get_month_start_end_dates(month_int, year_int)
  # outdoor_raw_urls <- get_file_urls(
  #   start_date = month_dates[["month_start_date"]],
  #   stop_date = month_dates[["month_end_date"]],
  #   sensor_id = location_data[["outdoor_sensor_ID"]]
  # )
  # indoor_raw_urls <- get_file_urls(
  #   start_date = month_dates[["month_start_date"]],
  #   stop_date = month_datesa[["month_end_date"]],
  #   sensor_id = location_data[["indoor_sensor_ID"]]
  # )

  outdoor_csv_status <- create_processed_csv(
    raw_git_urls = outdoor_raw_urls,
    data_includes_time_change = FALSE,
    month_folder = "October2025",
    is_outdoor_data = TRUE
  )
  if (!(is.null(outdoor_csv_status))) {
    print(sprintf("Successfully generated outdoor csv for %s", location))
  } else {
    print(sprintf(
      "Missing date files, no outdoor csv generated for %s", location
    ))
  }
  indoor_csv_status <- create_processed_csv(
    raw_git_urls = indoor_raw_urls,
    data_includes_time_change = FALSE,
    month_folder = "October2025",
    is_outdoor_data = FALSE
  )
  if (!(is.null(indoor_csv_status))) {
    print(sprintf("Successfully generated indoor csv for %s", location))
  } else {
    print(sprintf(
      "Missing date files, no indoor csv generated for %s", location
    ))
  }
}