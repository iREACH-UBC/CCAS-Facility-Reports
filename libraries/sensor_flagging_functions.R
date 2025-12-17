#' Calculates the proportion of time a sensor is operational. Assumes
#'  sensor data is sampled every 15 minutes and neglects file timing
#'  inconsistencies at the end/start of daily git files.
#'
#' @param data_df Dataframe of processed sensor data. Dates are in POSIX format.
#' @param target_start_date_char Char representing target start date in
#'  sensor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param target_end_date_char Char representing target end date in
#'  sensor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @return Double value between 0 (0% uptime) and 1 (100% uptime).
get_sensor_uptime <- function(
  data_df, target_start_date_char, target_end_date_char
) {
  if (nrow(data_df) == 0) { # Check for empty data
    return(0)
  }
  timezone <- lubridate::tz(data_df$date)
  first_expected_df_date <- as.POSIXct(target_start_date_char, tz = timezone)
  last_expected_df_date <- as.POSIXct(target_end_date_char, tz = timezone)

  # indices relative to rows of data_df rows
  post_outage_na_indices <- which(
    is.na(data_df$NO) & is.na(data_df$NO2) &
      is.na(data_df$CO) & is.na(data_df$O3)
  )
  if (length(post_outage_na_indices) == 0) {
    return(1)
  }
  # indices relative to post_outage_na_indices
  start_post_outage_indices <- c(1, which(
    (post_outage_na_indices[1:(length(post_outage_na_indices) - 1)] + 1) !=
      post_outage_na_indices[2:length(post_outage_na_indices)]
  ) + 1)
  # indices relative to post_outage_na_indices
  if (length(start_post_outage_indices) == 1) {
    end_post_outage_indices <- length(post_outage_na_indices)
  } else {
    end_post_outage_indices <- c(
      (start_post_outage_indices[2:length(start_post_outage_indices)] - 1),
      length(post_outage_na_indices)
    )
  }
  # Get indices of dataframe rows before/after sensor outage
  before_outage_indices <- post_outage_na_indices[start_post_outage_indices] - 1
  after_outage_indices <- post_outage_na_indices[end_post_outage_indices] + 1

  # Get dates before/after sensor outage
  dates_before_outage <- as.POSIXct(data_df$date[before_outage_indices])
  dates_after_outage <- as.POSIXct(data_df$date[after_outage_indices])
  if (before_outage_indices[[1]] == 0) {
    dates_before_outage <- c(first_expected_df_date, dates_before_outage)
  }
  if (after_outage_indices[[
    length(after_outage_indices)
  ]] == (nrow(data_df) + 1)) {
    dates_after_outage[[length(dates_after_outage)]] <- last_expected_df_date
  }

  # Calculate number of dates missed due to outages
  diff_minutes <- as.double(difftime(
    dates_after_outage, dates_before_outage, units = "mins"
  ))
  times_missed <- round((diff_minutes - 15) / 15)
  num_times_missed <- sum(times_missed)

  # Get total number of expected dates and calculate sensor uptime
  total_num_times <- nrow(data_df) + num_times_missed -
    length(post_outage_na_indices)
  (total_num_times - num_times_missed) / total_num_times
}


#' Counts the number of different times for each day in a dataset.
#'  Assumes no duplicate date entries.
#'
#' @param dataset Dataframe of processed sensor data. Dates are in POSIX format.
#' @param start_date_char Char representing target start date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format, and in same timezone as 
#'  sensor dataset.
#' @param end_date_char Char representing target end date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format, and in same timezone as 
#'  sensor dataset.
#' @return Dataframe of dates and number of different times per date.
get_actual_num_times_per_date <- function(dataset, start_date_char, end_date_char) {
  timezone <- lubridate::tz(dataset$date)

  # Remove dataset rows with sensor outages
  outage_indices <- which(
    is.na(dataset$NO) & is.na(dataset$NO2) &
      is.na(dataset$CO) & is.na(dataset$O3)
  )
  df_without_outage_data <- dataset[-outage_indices, ]

  # Get dataset dates w/ outages omitted
  dates_without_outages <- substr(
    as.character(dataset[-outage_indices, ]$date), 1, 10
  )
  # Get all dates within the start and end date, inclusive
  all_dates <- as.character(seq(
    from = as.Date(start_date_char), to = as.Date(end_date_char), by = "day"
  ))

  date_match_indices <- match(dates_without_outages, all_dates)
  num_times_per_date <- tabulate(date_match_indices, nbins = length(all_dates))
  num_times_per_date_df <- data.frame(date = all_dates, count = num_times_per_date)
}


#' Gets the expected number of different times for each day in a dataset.
#'  Assumes no duplicate date entries and assumes 15 minute data intervals.
#'
#' @param dataset Dataframe of processed sensor data. Dates are in POSIX format.
#' @param start_date_char Char representing target start date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format, and in same timezone as 
#'  sensor dataset.
#' @param end_date_char Char representing target end date in dataset.
#'  Represents date in YYYY-MM-DD HH:MM:SS format, and in same timezone as 
#'  sensor dataset.
#' @return Dataframe of dates and expected number of different times per date.
get_expected_num_times_per_date <- function(
  dataset, start_date_char, end_date_char
) {
  expected_times_per_hr <- 4 # 15 min intervals
  expected_times_per_day <- expected_times_per_hour * 24
  timezone <- lubridate::tz(dataset$date)

  dates <- seq(
    from = substr(start_date_char, 1, 10),
    to = substr(end_date_char, 1, 10),
    by = "day"
  )
  count <- rep(expected_times_per_day, times = length(dates))
  last_time_first_day <- sprintf("%s 23:45:00", as.Date(start_date_char))
  first_time_last_day <- sprintf("%s 00:00:00", as.Date(end_date_char))

  diff_minutes_first_day <- as.double(difftime(
    as.POSIXct(last_time_first_day, tz = timezone),
    as.POSIXct(start_date_char, tz = timezone),
    units = "mins"
  ))
  diff_minutes_last_day <- as.double(difftime(
    as.POSIXct(end_date_char, tz = timezone),
    as.POSIXct(first_time_last_day, tz = timezone),
    units = "mins"
  ))

  count[[1]] <- as.integer((diff_minutes_first_day - 15) / 15)
  count[length(count)] <- as.integer((diff_minutes_last_day - 15) / 15)
  times_per_date <- data.frame(date = dates, count = count)
}