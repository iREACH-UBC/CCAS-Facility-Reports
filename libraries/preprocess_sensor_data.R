time_processor <- modules::use("libraries/time_processing_functions.R")
file_processor <- modules::use("libraries/file_processing_functions.R")

#' Processes calibrated sensor data (from Git) to a form usable by report
#'  generator. Use this processing function if your dataframe came from git
#'  data collection pipeline.
#'
#' @param calibrated_dataset_df A dataframe of calibrated sensor data
#'  from git. Dataframe should have no date overlaps aside from
#'  time change. Assumes all pollutant column types are present, including AQHI,
#'  and that all dates are in local Vancouver time but with UTC timestamp.
#' @param month_int Integer representing month of year.
#' @param year_int Integer representing year.
#' @param start_date_char Char representing target start date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char Char representing target end date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format.
#' @return Dataframe of processed sensor data.
process_sensor_data_df <- function(
  calibrated_dataset_df, month_int, year_int,
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
  pollutant_data$date <- time_processor$set_timezone_from_month(
    pollutant_data$date, month_int, year_int,
    FALSE # Git data is in local time
  )
  # Remove dates before start and after end dates
  pollutant_data <- time_processor$remove_out_of_range_data(
    pollutant_data, start_date_char, end_date_char
  )
  pollutant_data #Implicit return
}


#' Processes manually calibrated sensor data to a form usable by
#'  report generator. Use this processing function if your dataframe
#'  did not come from git data collection pipeline.
#'
#' @param calibrated_dataset_df A dataframe of manually calibrated sensor data.
#'  Dataframe should have no date overlaps aside from time change. Assumes AQHI
#'  column is missing from dataset. Dates must be in UTC or local time, and
#'  must have a UTC timestamp (even if in local time).
#' @param start_date_char Char representing target start date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char Char representing target end date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format.
#' @param df_dates_in_utc TRUE if dataset dates are in UTC, FALSE if dates
#'  are in local time. Note that timezone stamp may read UTC even if dates
#'  are in local time (ex. if readr::read_csv is used).
#' @param month_int Integer representing month of year.
#' @param year_int Integer representing year.
#' @return Dataframe of processed sensor data.
process_pollutant_data_df <- function(
  pollutant_df, start_date_char, end_date_char,
  df_dates_in_utc, month_int, year_int
) {
  # Extra processing if date is read as a character
  if (typeof(pollutant_df$date) != "double") {
    # Add time to date if missing
    pollutant_df$date <- ifelse(
      grepl(":", pollutant_df$date),
      pollutant_df$date,
      paste0(pollutant_df$date, " 00:00:00")
    )
    # Convert time to POSIX w/ UTC timestamp
    # Done to be consistent with typical read_csv output in case read.csv used
    pollutant_df$date <- as.POSIXct(pollutant_df$date, tz = "UTC")
  }
  # Add AQHI column
  pollutant_df$AQHI <- file_processor$get_aqhi_column(pollutant_df)

  # Set dates to consistent timezone
  pollutant_df$date <- time_processor$set_timezone_from_month(
    pollutant_df$date, month_int, year_int, df_dates_in_utc
  )
  # Remove data before start and after end dates
  pollutant_df <- time_processor$remove_out_of_range_data(
    pollutant_df, start_date_char, end_date_char
  )
  invisible(pollutant_df)
}


#' Given a csv directory, generates sensor data that is ready to use in
#'  CCAS report generator.
#'
#' @param csv_dir Directory (char) of sensor data csv.
#' @param csv_from_git TRUE if csv came from git data collection pipeline,
#'  FALSE if csv generated manually.
#' @param csv_data_is_processed TRUE if csv data has been processed to
#'  run in CCAS report generator, FALSE otherwise. Csv is processed if it
#'  has date, pollutant data, and AQHI columns only.
#' @param start_date_char Char representing target start date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char Char representing target end date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format.
#' @param dates_in_utc TRUE if csv dates are in UTC timezone,
#'  FALSE if in local time. Always FALSE if data came from Git.
#' @param month_int Integer representing month.
#' @param year_int Integer representing year.
get_processed_df_from_csv <- function(
  csv_dir, csv_from_git, csv_data_is_processed,
  start_date_char, end_date_char, dates_in_utc,
  month_int, year_int
) {
  df <- readr::read_csv(csv_dir)
  if (!(csv_data_is_processed)) {
    if (csv_from_git) {
      df <- process_sensor_data_df(
        df, month_int, year_int, start_date_char, end_date_char
      )
    } else {
      df <- process_pollutant_data_df(
        df, start_date_char, end_date_char,
        dates_in_utc, month_int, year_int
      )
    }
  }
}