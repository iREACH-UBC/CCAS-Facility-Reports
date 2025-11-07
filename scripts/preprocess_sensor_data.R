# Current script saves csvs of processed outdoor data based on json
# TODO: Modify for full automation
# TODO: Modify if you delete start and end dates from json

# library(jsonlite)
# source("helper_functions.R")

# sensor_metadata <- fromJSON("sensor_data.json")
# includes_time_change <- sensor_metadata$includes_time_change
# month_char <- sensor_metadata$month
# year_int <- sensor_metadata$year

# fields_to_remove <- c("includes_time_change", "month", "year")
# sensor_metadata <- sensor_metadata[setdiff(
#   names(sensor_metadata), fields_to_remove
# )]

source("helper_functions.R")

sensor_metadata <- extract_sensor_data_from_json(
  "sensor_data.json"
)[["sensor_data"]]

for (location in names(sensor_metadata)) {
  location_data <- sensor_metadata[[location]]

  if (!is.null(location_data[["outdoor_sensor_ID"]])) {
    raw_urls <- get_file_urls(
      start_date = location_data[["outdoor_data_start_date"]],
      stop_date = location_data[["outdoor_data_end_date"]],
      sensor_id = location_data[["outdoor_sensor_ID"]]
    )
    create_processed_csv(raw_urls, includes_time_change)
  }
}