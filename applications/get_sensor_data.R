source("libraries/helper_functions.R")
source("applications/preprocess_sensor_data.R")

# TODO: REMOVE ALL NON-FUNCTIONS AFTER TESTING DONE

# Get metadata used in processing
# Assumes same start/end dates for each sensor
# Make your own script for any sensors whose dates differ
# Start user adjustable parameters
json_file_dir <- "sensor_data.json"
month_char <- "October"
month_int <- match(month_char, month.name) # Do not change
year_int <- 2025
month_dates <- get_month_start_end_dates(month_int, year_int)
start_date_char <- month_dates[["month_start_date"]]
end_date_char <- month_dates[["month_end_date"]]
# End user adjustable parameters

sensor_data <- jsonlite::fromJSON(json_file_dir)
includes_time_change <- data_includes_time_change(
  month_int, start_date_char, end_date_char, year_int
)

# process a single df over start and end range
# Assumes up to one month of data collected, all in same month
process_sensor_df_from_git <- function(
  start_date_char, end_date_char, sensor_id,
  month_char, year_int
) {
  
}

# Generates list of outdoor and indoor sensor dfs
# start and stop date in YYYY-MM-DD format
# Output dfs are ready to be sent to processing script without further changes
# Assumes max one month worth of data, all data for same month
# For March: choose end date as April 1st to avoid time change data loss
# Other than March end date, all start/stop dates must be in same month
get_all_processed_sensor_dfs <- function(
  sensor_data, start_date_char, end_date_char, includes_time_change,
  outdoor_location_folder, indoor_location_folder
) {
  month_int <- lubridate::month(start_date_char)
  month_char <- month.name[month_int]
  year_int <- lubridate::year(start_date_char)

  # Get timezone of data
  if (includes_time_change) {
    timezone <- "Etc/GMT+8" # PST
  } else {
    timezone <- "US/Pacific" # PST or PDT
  }

  # Prepare sensor df lists
  locations <- names(sensor_data)
  outdoor_sensor_df_list <- vector("list", length(locations))
  indoor_sensor_df_list <- vector("list", length(locations))
  names(outdoor_sensor_df_list) <- locations
  names(indoor_sensor_df_list) <- locations
  sensor_id_types <- c("outdoor_sensor_ID", "indoor_sensor_ID")

  # Get dfs for indoor/outdoor sensors at each location
  # Assumes one outdoor/indoor sensor pair per location
  for (location in names(sensor_data)) {
    location_data <- sensor_data[[location]]

    # Create and add processed dfs to outdoor and indoor dfs lists
    for (id_type in sensor_id_types) {
      sensor_id <- location_data[id_type]

      raw_urls <- get_file_urls(
        start_date = start_date_char,
        stop_date = end_date_char,
        sensor_id = sensor_id
      )
      sensor_data_df <- get_df_from_raw_git_urls(raw_urls) # Dates in POSIXct

      # Save csv of sensor data
      if (!(is.null(sensor_data_df))) {
        processed_sensor_data_df <- process_sensor_data_df(
          includes_time_change, sensor_data_df, month_int, year_int,
          start_date_char, end_date_char
        )
        month_folder <- sprintf("%s%s", month_char, year_int)
        if (id_type == "outdoor_sensor_ID") {
          outdoor_sensor_df_list[[location]] <- processed_sensor_data_df
          location_folder <- outdoor_location_folder
        } else { # indoor
          indoor_sensor_df_list[[location]] <- processed_sensor_data_df
          location_folder <- indoor_location_folder
        }
        data_destination <- file.path(location_folder, month_folder)
        if (!(dir.exists(data_destination))) {
          dir.create(data_destination)
        }
        data.table::fwrite(
          transform(
            processed_sensor_data_df, date = format(date, tz = timezone)
          ), file.path(
            location_folder, month_folder, sprintf(
              "%s.csv", sensor_id
            )
          )
        )
        print(sprintf("Created csv for %s", sensor_id))
      } else {
        print(sprintf("Could not generate a dataframe for %s", sensor_id))
      }
    }
  }
  invisible(list(
    "outdoor_sensor_data" = outdoor_sensor_df_list,
    "indoor_sensor_data" = indoor_sensor_df_list
  )) # Return w/o print
}


# location_folder is either indoor or outdoor folder, is location of output
# start and end date in YYYY-MM-DD format, represent local time
# Use if you can't get files from github and have a semi-processed csv
# For March: choose end date as April 1st to avoid time change data loss
# Other than March end date, all start/stop dates must be in same month
process_sensor_df_from_csv <- function(
  sensor_csv_dir, location_folder,
  sensor_id,
  start_date, end_date, times_in_utc,
  includes_time_change, month_int, year_int
) {
  month_char <- month.name[month_int]

  # Read and process sensor data
  unprocessed_sensor_data_df <- readr::read_csv(
    sensor_csv_dir, show_col_types = FALSE
  )
  processed_sensor_data_df <- process_pollutant_data_df(
    unprocessed_sensor_data_df, start_date, end_date, times_in_utc,
    includes_time_change, month_int, year_int
  )
  # Get timezone of data
  if (includes_time_change) {
    timezone <- "Etc/GMT+8" # PST
  } else {
    timezone <- "US/Pacific" # PST or PDT
  }
  # Prepare csv destination
  month_folder <- sprintf("%s%s", month_char, year_int)
  data_destination <- file.path(location_folder, month_folder)
  if (!(dir.exists(data_destination))) {
    dir.create(data_destination)
  }
  # Save data to csv
  data.table::fwrite(
    transform(
      processed_sensor_data_df, date = format(date, tz = timezone)
    ), file.path(
      location_folder, month_folder, sprintf("%s.csv", sensor_id)
    )
  )
  invisible(processed_sensor_data_df) # Return sensor df
}
