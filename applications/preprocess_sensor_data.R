source("libraries/helper_functions.R")

# Used on dfs obtained from reading from github (local time)
# Assumes all column types present, including AQHI
process_sensor_data_df <- function(
  data_includes_time_change, calibrated_dataset_df, month_int, year_int,
  start_date_char, end_date_char
) {
  pollutant_data <- calibrated_dataset_df[c(
    "DATE", "CO", "NO2", "NO", "O3", "PM2.5", "CO2", "AQHI"
  )]
  # Reformat date field to meet timeAverage name requirements
  names(pollutant_data)[names(pollutant_data) == "DATE"] <- "date"

  # Reformat PM2.5
  names(pollutant_data)[names(pollutant_data) == "PM2.5"] <- "PM2_5"

  # Get consistent timezone for all dates
  pollutant_data$date <- set_timezone_from_month(
    pollutant_data$date, data_includes_time_change, month_int, year_int,
    FALSE # Git data is in local time
  )
  # Remove dates before start and after end dates
  final_timezone <- lubridate::tz(pollutant_data$date[1])
  pollutant_data <- remove_out_of_range_data(
    pollutant_data, final_timezone, start_date_char, end_date_char
  )
  pollutant_data #Implicit return
}

# Assumes that only date, pollutant and PM2.5 rows included in dataframe
# Assumes DATE has already been renamed to date
# Assumes dates always have UTC timestamp
# Assumes dates are in UTC if csv_dates_in_utc is true
# Assumes dates are in local time but with UTC timestamp otherwise
# Start and end date in YYYY-MM-DD format
process_pollutant_data_df <- function(
  pollutant_df, start_date_char, end_date_char, csv_dates_in_utc,
  data_includes_time_change, month_int, year_int
) {
  # Extra processing if date is read as a character
  if(typeof(pollutant_df$date) != "double") {
    # Add time to date if missing
    pollutant_df$date <- ifelse(
      grepl(":", pollutant_df$date),
      pollutant_df$date,
      paste0(pollutant_df$date, " 00:00:00") # Remove SS if openair complains
    )
    # Convert time to POSIX w/ UTC timestamp
    # Done to be consistent with typical read_csv output
    # Done in case read.csv used
    pollutant_df$date <- as.POSIXct(pollutant_df$date, tz = "UTC")
  }
  # Add AQHI column
  pollutant_df$AQHI <- get_aqhi_column(pollutant_df)

  # Set dates to consistent timezone
  pollutant_df$date <- set_timezone_from_month(
    pollutant_df$date, data_includes_time_change, month_int, year_int,
    csv_dates_in_utc
  )
  # Remove data before start and after end dates
  final_timezone <- lubridate::tz(pollutant_df$date[1])
  pollutant_df <- remove_out_of_range_data(
    pollutant_df, final_timezone, start_date_char, end_date_char
  )
  invisible(pollutant_df)
}