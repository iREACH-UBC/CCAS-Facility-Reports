source("libraries/time_processing_functions.R")
source("libraries/file_processing_functions.R")
source("applications/data_io.R")

#' Processes calibrated sensor data (from Git) to a form usable by report
#'  generator. Use this processing function if your dataframe came from git
#'  data collection pipeline.
#'
#' @param calibrated_dataset_df A dataframe of calibrated sensor data
#'  from git. Dataframe should have no date overlaps aside from
#'  time change. Assumes all pollutant column types are present, including AQHI,
#'  and that all dates are in local Vancouver time. If dates are in POSIX,
#'  assume they have UTC timestamps even though dates represent Vancouver time.
#' @param month_int Integer representing month of year.
#' @param year_int Integer representing year.
#' @param start_date_char Char representing target start date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in 
#'  Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char Char representing target end date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in 
#'  Nov-Mar, and PDT if dates in Apr-Oct.
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

  # Extra processing if date is read as a character
  if (typeof(pollutant_data$date) != "double") {
    # Add time to date if missing
    pollutant_data$date <- ifelse(
      grepl(":", pollutant_data$date),
      pollutant_data$date,
      paste0(pollutant_data$date, " 00:00:00")
    )
    # Convert time to POSIX w/ UTC timestamp
    # Done to be consistent with typical read_csv output in case read.csv used
    pollutant_data$date <- as.POSIXct(pollutant_df$date, tz = "UTC")
  }
  # Get consistent timezone for all dates
  pollutant_data$date <- set_timezone_from_month(
    pollutant_data$date, month_int, year_int,
    FALSE # Git data is in local time
  )
  # Remove dates before start and after end dates
  pollutant_data <- remove_out_of_range_data(
    pollutant_data, start_date_char, end_date_char
  )
  pollutant_data #Implicit return
}


#' Processes manually calibrated sensor data to a form usable by
#'  report generator. Use this processing function if your dataframe
#'  did not come from git data collection pipeline.
#'
#' @param pollutant_df A dataframe of manually calibrated sensor data.
#'  Dataframe should have no date overlaps aside from time change. Assumes AQHI
#'  column is missing from dataset. Dates must represent UTC or local time, and
#'  must have a UTC timestamp (even if in local time) if in POSIX format.
#' @param start_date_char Char representing target start date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in 
#'  Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char Char representing target end date in dataset,
#'  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in 
#'  Nov-Mar, and PDT if dates in Apr-Oct.
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
  pollutant_df$AQHI <- get_aqhi_column(pollutant_df)

  # Set dates to consistent timezone
  pollutant_df$date <- set_timezone_from_month(
    pollutant_df$date, month_int, year_int, df_dates_in_utc
  )
  # Remove data before start and after end dates
  pollutant_df <- remove_out_of_range_data(
    pollutant_df, start_date_char, end_date_char
  )
  invisible(pollutant_df)
}


#' Given a csv directory, generates sensor data that is ready to use in
#'  CCAS report generator. Assumes that csv has already been processed to run
#'  in CCAS report generator if it is in the standard outdoor or indoor
#'  processed data folder. Assumes that csv came from Github if it has
#'  same columns and same column ordering as Github files, or that csv
#'  came from manual calibrations if it contains same columns with same
#'  column ordering as manually calibrated data.
#'
#' @param csv_dir Directory (char) of sensor data csv.
#' @param start_date_char Char representing target start date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST time
#'  if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char Char representing target end date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST time
#'  if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param outdoor_processed_data_folder Name (char) of outdoor
#'  processed data folder.
#' @param indoor_processed_data_folder Name (char) of indoor
#'  processed data folder.
#' @param dates_in_utc TRUE if csv dates are in UTC timezone,
#'  FALSE if in local time. Always FALSE if data is processed
#'  (in a processed data folder). Manual data from RAMPs are
#'  often in local time, and manual data from QAQs are often in UTC.
#' @param month_int Integer representing month.
#' @param year_int Integer representing year.
#' @return Dataframe of processed sensor data.
get_processed_df_from_csv <- function(
  csv_dir, start_date_char, end_date_char,
  outdoor_processed_data_folder, indoor_processed_data_folder,
  dates_in_utc, month_int, year_int
) {
  df <- readr::read_csv(csv_dir, show_col_types = FALSE)
  #Normalize DATE column name to date
  names(df)[names(df) == "DATE"] <- "date"

  if ( # Check if csv data is processed
    (length(grep(indoor_processed_data_folder, csv_dir)) != 0) || (
      length(grep(outdoor_processed_data_folder, csv_dir)) != 0
    )
  ) {
    # Set timezone manually
    if (month_int == 3 || month_int == 11) {
      df$date <- lubridate::force_tz(
        df$date, tzone = "Etc/GMT+8"
      )
    } else {
      df$date <- lubridate::force_tz(
        df$date, tzone = "US/Pacific"
      )
    }
    df # Return already processed df
  } else {
    if (sensor_data_is_from_git(names(df))) {
      # Process data from Github
      df <- process_sensor_data_df(
        df, month_int, year_int, start_date_char, end_date_char
      )
    } else if (sensor_data_manually_generated(names(df))) {
      # Process manually calibrated data
      df <- process_pollutant_data_df(
        df, start_date_char, end_date_char,
        dates_in_utc, month_int, year_int
      )
    } else {
      stop("File format is not recognized or file is misplaced")
    }
  }
}
