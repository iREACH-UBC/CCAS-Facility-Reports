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

source("libraries/helper_functions.R")

sensor_metadata <- extract_sensor_data_from_json(
  "sensor_data.json"
)
sensor_data <- sensor_metadata[["sensor_data"]]
data_includes_time_change <- sensor_metadata[["includes_time_change"]]
month_char <- sensor_metadata[["month_char"]]
year_int <- sensor_metadata[["year_int"]]

#TODO- REMOVE
month_char <- "October"

# location_type is "outdoor" or "indoor"
# location folder is "indoor_data_processed" or "outdoor_data_processed"
# function also saves the data to a csv
preprocess_sensor_data <- function(
  sensor_data, data_includes_time_change, month_char, year_int, location_type
) {
  month_int <- match(month_char, month.name)

  for (location in names(sensor_data)) {
    location_data <- sensor_data[[location]]
    sensor_id <- location_data[[
      sprintf("%s_sensor_ID", location_type)
    ]]

    # # Use if dates differ from full month
    # raw_urls <- get_file_urls(
    #   start_date = location_data[[
    #     sprintf("%s_data_start_date", location_type)
    #   ]],
    #   stop_date = location_data[[
    #     sprintf("%s_data_end_date", location_type)
    #   ]],
    #   sensor_id = sensor_id
    # )

    # Use if dates are full month for all sensors
    month_dates <- get_month_start_end_dates(month_int, year_int)
    raw_urls <- get_file_urls(
      start_date = month_dates[["month_start_date"]],
      stop_date = month_dates[["month_end_date"]],
      sensor_id = location_data[[
        sprintf("%s_sensor_ID", location_type)
      ]]
    )
    print(length(raw_urls))
    print("Got raw urls")

    unprocessed_df <- get_df_from_calibrated_csvs(raw_urls)
    print(length(unprocessed_df$DATE))
    print("Got df from csvs")
    print(colnames(unprocessed_df))
    print(names(unprocessed_df))
    print("Got df from csvs")
    processed_df <- process_calibrated_data_df(
      data_includes_time_change,
      unprocessed_df,
      month_int,
      year_int
    )
    print(colnames(processed_df))
    print("Processed df successfully")

    month_folder <- sprintf("%s%s", month_char, year_int)
    location_folder <- sprintf("test_%s_data", location_type) #TODO: change
    report_folder <- file.path(location_folder, month_folder)

    if (!(dir.exists(report_folder))) {
      dir.create(report_folder)
    }
    data.table::fwrite(
      transform(processed_df, date = format(date, tz = TODO: INSERT TIMEZONE)
      file.path(location_folder, month_folder, sprintf("%s.csv", sensor_id))
    )
    print("Saved sensor csv")
  }
}

# for (location in names(sensor_data)) {
#   location_data <- sensor_data[[location]]

#   # Use if dates differ from full month
#   outdoor_raw_urls <- get_file_urls(
#     start_date = location_data[["outdoor_data_start_date"]],
#     stop_date = location_data[["outdoor_data_end_date"]],
#     sensor_id = location_data[["outdoor_sensor_ID"]]
#   )
#   indoor_raw_urls <- get_file_urls(
#     start_date = location_data[["indoor_data_start_date"]],
#     stop_date = location_data[["indoor_data_end_date"]],
#     sensor_id = location_data[["indoor_sensor_ID"]]
#   )

#   # # Use if dates are full month for all sensors
#   # month_dates <- get_month_start_end_dates(month_int, year_int)
#   # outdoor_raw_urls <- get_file_urls(
#   #   start_date = month_dates[["month_start_date"]],
#   #   stop_date = month_dates[["month_end_date"]],
#   #   sensor_id = location_data[["outdoor_sensor_ID"]]
#   # )
#   # indoor_raw_urls <- get_file_urls(
#   #   start_date = month_dates[["month_start_date"]],
#   #   stop_date = month_datesa[["month_end_date"]],
#   #   sensor_id = location_data[["indoor_sensor_ID"]]
#   # )

#   # create_processed_csv(raw_urls, includes_time_change) #prev function

#   unprocessed_outdoor_df <- get_df_from_calibrated_csvs(outdoor_raw_urls)
#   unprocessed_outdoor_df <- get_df_from_calibrated_csvs(outdoor_raw_urls)

#   processed_outdoor_df <- process_calibrated_data_df(
#     data_includes_time_change,
#     unprocessed_outdoor_df,
#     month_int,
#     year_int
#   )
#   processed_indoor_df <- process_calibrated_data_df(
#     data_includes_time_change,
#     unprocessed_indoor_df,
#     month_int,
#     year_int
#   )

#   fwrite(
#     processed_outdoor_df,
#     file.path(location_folder, month_folder, sprintf("%s.csv", sensor_id))
#   )
# }