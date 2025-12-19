source("libraries/file_processing_functions.R")

#' Counts the number of different times where non-NA pollutant
#'  data (NO2, NO, CO, O3) is reported in a dataset.
#'
#' @param dataset Dataframe of processed sensor data. Assumes no duplicate
#'  date entries in dataset.
#' @return Number (int) of different times in the dataset.
get_actual_num_times_per_dataset <- function(dataset) {
  # Remove dataset rows with sensor outages
  outage_indices <- which(
    is.na(dataset$NO) & is.na(dataset$NO2) &
      is.na(dataset$CO) & is.na(dataset$O3)
  )
  if (length(outage_indices) != 0) {
    df_without_outage_data <- dataset[-outage_indices, ]
    nrow(df_without_outage_data)
  } else {
    nrow(dataset)
  }
}


#' Gets the expected number of different times where non-NA pollutant data
#'  (NO2, NO, CO, O3) is reported in a dataset. Assumes data is measured in
#'  15 minute time intervals.
#'
#' @param start_date_char Char representing target start date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST
#'  time if the dataset is for a month in Nov-Mar, and PDT if the
#'  dataset is for a month in Apr-Oct.
#' @param end_date_char Char representing target end date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST
#'  time if the dataset is for a month in Nov-Mar, and PDT if the
#'  dataset is for a month in Apr-Oct.
#' @return Expected number (int) of different times per date.
get_expected_num_times_per_dataset <- function(
  start_date_char, end_date_char
) {
  if (start_date_char == end_date_char) {
    expected_num <- 0
  } else {
    start <- as.POSIXct(start_date_char, tz = "UTC")
    stop <- as.POSIXct(end_date_char, tz = "UTC")
    expected_num <- as.integer(
      as.double(difftime(stop, start, units = "mins") / 15)
    ) + 1
  }
}


#' Calculates the proportion of time a sensor is operational. Assumes
#'  sensor data is sampled every 15 minutes.
#'
#' @param dataset Dataframe of processed sensor data. Assumes no duplicate
#'  date entries in dataset. Dataframe must not have date entries before
#'  start date or after stop date.
#' @param start_date_char Char representing target start date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST
#'  time if the dataset is for a month in Nov-Mar, and PDT if the
#'  dataset is for a month in Apr-Oct.
#' @param end_date_char Char representing target end date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST
#'  time if the dataset is for a month in Nov-Mar, and PDT if the
#'  dataset is for a month in Apr-Oct.
#' @return Expected number (int) of different times per date.
get_sensor_uptime <- function(
  dataset, start_date_char, end_date_char
) {
  get_actual_num_times_per_dataset(dataset) /
    get_expected_num_times_per_dataset(start_date_char, end_date_char)
}


#' Returns the sensor data provided but with certain days' data removed
#'  if sensor uptime over those days is less than the data proportion.
#'
#' @param dataset Dataframe of processed sensor data. Assumes no duplicate
#'  date entries in dataset. Dataframe must not have date entries before
#'  start date or after stop date.
#' @param start_date_char Char representing target start date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST
#'  time if the dataset is for a month in Nov-Mar, and PDT if the
#'  dataset is for a month in Apr-Oct.
#' @param end_date_char Char representing target end date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST
#'  time if the dataset is for a month in Nov-Mar, and PDT if the
#' @param uptime_threshold Double between 0 and 1 representing sensor
#'  uptime proportion. This value is a chosen sensor uptime threshold;
#'  dates with uptimes below this threshold are removed from the dataset.
#'  dataset is for a month in Apr-Oct.
#' @return Dataframe of sensor dataset after omitting days with low uptime.
remove_days_with_low_uptime <- function(
  dataset, start_date_char, end_date_char, uptime_threshold
) {
  # Separate dataframes by day
  daily_df_list <- separate_df_by_day(
    dataset,
    substr(start_date_char, 1, 10),
    substr(end_date_char, 1, 10)
  )
  # Get all dates within and including the start/end dates
  all_dates <- as.character(seq(
    from = as.Date(start_date_char),
    to = as.Date(end_date_char),
    by = "day"
  ))
  # Get a start and stop time for each date in range
  all_start_dates <- sprintf("%s 00:00:00", all_dates)
  all_start_dates[[1]] <- start_date_char
  all_end_dates <- sprintf("%s 23:45:00", all_dates)
  all_end_dates[length(all_end_dates)] <- end_date_char

  # Calculate uptime for each date of the dataset
  daily_uptimes <- Map(
    get_sensor_uptime,
    daily_df_list,
    all_start_dates,
    all_end_dates
  )
  # Return dataset after omitting days with low uptime
  dates_to_eliminate <- names(daily_uptimes)[unlist(daily_uptimes) < uptime_threshold]
  indices_of_rows_to_delete <- which(
    substr(as.character(dataset$date), 1, 10) %in% dates_to_eliminate
  )
  if (length(indices_of_rows_to_delete) == 0) {
    dataset
  } else{
    dataset[-indices_of_rows_to_delete, ]
  }
}