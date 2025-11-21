source("libraries/helper_functions.R")
source("applications/preprocess_sensor_data.R")

# Get data from sensor json
sensor_metadata <- extract_sensor_data_from_json(
  "sensor_data.json"
)
sensor_data <- sensor_metadata[["sensor_data"]]
month_char <- sensor_metadata[["month_char"]]
month_int <- match(month_char, month.name)
year_int <- sensor_metadata[["year_int"]]
includes_time_change <- sensor_metadata[["includes_time_change"]]

# Generates list of outdoor and indoor sensor dfs
# start and stop date in YYYY-MM-DD format
# Output dfs are ready to be sent to processing script without further changes
# Assumes max one month worth of data, all data for same month
# For March: choose end date as April 1st to avoid time change data loss
# Other than March or Nov, all file start/stop must be in same month
get_all_processed_sensor_dfs <- function(
  sensor_data, start_date, end_date, includes_time_change,
  outdoor_location_folder, indoor_location_folder
) {
  month_int <- lubridate::month(start_date)
  month_char <- month.name[month_int]
  year_int <- lubridate::year(start_date)

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
  for (location in names(sensor_data)[12]) {
    location_data <- sensor_data[[location]]

    # Create and add processed dfs to outdoor and indoor dfs lists
    for (id_type in sensor_id_types) {
      sensor_id <- location_data[id_type]

      raw_urls <- get_file_urls(
        start_date = start_date,
        stop_date = end_date,
        sensor_id = sensor_id
      )
      sensor_data_df <- get_df_from_raw_git_urls(raw_urls) # Dates in POSIXct

      if (!(is.null(sensor_data_df))) {
        processed_sensor_data_df <- process_sensor_data_df(
          includes_time_change, sensor_data_df, month_int, year_int
        )
        # Save dfs and write to csvs
        month_folder <- sprintf("%s%s", month_char, year_int)
        if (id_type == "outdoor_sensor_ID") {
          outdoor_sensor_df_list[[location]] <- processed_sensor_data_df
          data_destination <- file.path(outdoor_location_folder, month_folder)
          if (!(dir.exists(data_destination))) {
            dir.create(data_destination)
          }
          data.table::fwrite(
            transform(
              processed_sensor_data_df, date = format(date, tz = timezone)
            ), file.path(
              outdoor_location_folder, month_folder, sprintf(
                "%s.csv", sensor_id
              )
            )
          )
          print(sprintf("Created outdoor csv for %s", sensor_id))
        } else {
          indoor_sensor_df_list[[location]] <- processed_sensor_data_df
          data_destination <- file.path(indoor_location_folder, month_folder)
          if (!(dir.exists(data_destination))) {
            dir.create(data_destination)
          }
          data.table::fwrite(
            transform(
              processed_sensor_data_df, date = format(date, tz = timezone)
            ), file.path(
              indoor_location_folder, month_folder, sprintf("%s.csv", sensor_id)
            )
          )
          print(sprintf("Created indoor csv for %s", sensor_id))
        }
      } else {
        print(sprintf("Could not generate a dataframe for %s", sensor_id))
      }
    }
  }
  invisible(c(outdoor_sensor_df_list, indoor_sensor_df_list)) # Return w/o print
}

# sensor_df_list is either the indoor or outdoor df list
# location_folder is either indoor or outdoor folder, is location of output
# start and end date in YYYY-MM-DD format, represent local time or PST
# Use if you can't get files from github and have a semi-processed csv
# Assume there is only one month's data in dataset (can be <1 mo. but not more)
get_one_processed_sensor_df <- function(
  sensor_csv_dir, location_folder,
  sensor_id,
  start_date, end_date, times_in_UTC,
  includes_time_change
) {
  month_int <- lubridate::month(start_date)
  month_char <- month.name[month_int]
  year_int <- lubridate::year(start_date)

  # Read and process sensor data
  unprocessed_sensor_data_df <- readr::read_csv(
    sensor_csv_dir, show_col_types = FALSE
  )
  processed_sensor_data_df <- process_pollutant_data_df(
    unprocessed_sensor_data_df, start_date, end_date, times_in_UTC
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

# month_dates <- get_month_start_end_dates(month_int, year_int)

# get_all_processed_sensor_dfs(
#   sensor_data, month_dates[["month_start_date"]],
#   month_dates[["month_end_date"]],
#   includes_time_change, "test_outdoor", "test_indoor"
# )

get_all_processed_sensor_dfs(
  sensor_data, "2025-11-01",
  "2025-11-19", TRUE,
  "test_outdoor", "test_indoor"
)


# get_one_processed_sensor_df(
#   "2049_pred_2025_10_01 (1).csv", "test_indoor", "2049",
#   "2025-10-01", "2025-10-31", FALSE, FALSE
# )