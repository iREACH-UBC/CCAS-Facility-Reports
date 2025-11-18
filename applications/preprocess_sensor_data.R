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

    unprocessed_df <- get_df_from_calibrated_csvs(raw_urls)
    processed_df <- process_calibrated_data_df(
      data_includes_time_change,
      unprocessed_df,
      month_int,
      year_int
    )

    month_folder <- sprintf("%s%s", month_char, year_int)
    location_folder <- sprintf("test_%s_data", location_type) #TODO: change
    report_folder <- file.path(location_folder, month_folder)

    if (!(dir.exists(report_folder))) {
      dir.create(report_folder)
    }
    # TODO: change tz
    data.table::fwrite(
      transform(processed_df, date = format(date, tz = "US/Pacific")),
      file.path(location_folder, month_folder, sprintf("%s.csv", sensor_id))
    )
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

# Used on dfs obtained from reading from github 
# Assumes all rows present, including AQHI
process_sensor_data_df <- function(
  data_includes_time_change, calibrated_dataset_df, month_int, year_int
) {
  pollutant_data <- calibrated_dataset_df[c(
    "DATE", "CO", "NO2", "NO", "O3", "PM2.5", "CO2", "AQHI"
  )]
  # Reformat date field
  colnames(pollutant_data)[[1]] <- "date" # timeAverage requires "date" field

  # Reformat PM2.5
  names(pollutant_data)[names(pollutant_data) == "PM2.5"] <- "PM2_5"

  # Convert dates to local time or PST if time change
  dates <- pollutant_data$date
  if (data_includes_time_change) {
    time_change_date <- as.POSIXct(get_time_change_date(
      month_int, year_int
    ), tz = "UTC")
    if (month_int == 11) {
      end_pdt_index <- which( # RAMPs have data overlap
        dates[1:(length(dates) - 1)] > dates[2:length(dates)]
      )
      if (end_pdt_index == 0) { # QAQ have no overlap, data overwritten
        end_pdt_index <- tail(which(dates < time_change_date), 1)
      }
      dates_pst <- shift_timezones_at_time_change(
        dates, end_pdt_index, "Etc/GMT+7",
        "Etc/GMT+8", "Etc/GMT+8"
      )
    } else if (month_int == 3) {
      end_pst_index <- tail(which(dates < time_change_date), 1)
      dates_pst <- shift_timezones_at_time_change(
        dates, end_pst_index, "Etc/GMT+8",
        "Etc/GMT+7", "Etc/GMT+8"
      )
    }
    pollutant_data$date <- dates_pst
  } else {
    pollutant_data$date <- lubridate::force_tz(
      pollutant_data$date, tzone = "US/Pacific"
    )
  }
  pollutant_data #Implicit return
}


# Assumes that only date, pollutant and PM2.5 rows included in dataframe
# Assumes DATE has already been renamed to date
process_pollutant_data_df <- function(
  pollutant_df, data_includes_time_change, month_int, year_int
) {
    
}