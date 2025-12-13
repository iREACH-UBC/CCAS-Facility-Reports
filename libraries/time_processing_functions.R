# All time-related library functions


#' Gets the start and end dates of a month in YYYY-MM-DD HH:MM:SS format.
#' Time portion is 00:00:00 for start date, 23:45:00 for end date.
#'
#' @param month_int Integer representing month, ex. 2 for February.
#' @param year_int Year the data is from (int or char).
#' @return List composed of start and end dates (char).
#'  Use "month_start_date" or "month_end_date" to access start/end date
#' @examples
#' get_month_start_end_dates(12, 2025)
get_month_start_end_dates <- function(month_int, year) {
  month_num_char <- as.character(month_int)
  if (month_int - 10 < 0) {
    month_num_char <- sprintf("0%s", month_int)
  }
  start_date <- sprintf("%s-%s-01 00:00:00", year, month_num_char)
  month_abbrev <- month.abb[month_int]
  days_in_month <- lubridate::days_in_month(
    lubridate::ymd(sub(" .*", "", start_date))
  )[[month_abbrev]]
  end_date <- sprintf("%s-%s-%s 23:45:00", year, month_num_char, days_in_month)

  list("month_start_date" = start_date, "month_end_date" = end_date)
}


#' Sets the timezone of all dates to the final timezone
#'
#' @param dates Dates in POSIX. Dates before time change have timezone_b4
#'  timezone and dates after are in timezone_after, but the time zone
#'  identifiers may be different.
#' @param index_b4_change Index (int) of last date before time change.
#' @param timezone_b4 Timezone identifier (char) for times before time change.
#' @param timezone_after Timezone identifier (char) for times after time change.
#' @param final_timezone Timezone identifier (char) for final timezone.
#' @return Dates (char) with their timezone set to final_timezone.
shift_timezones_at_time_change <- function(
  dates, index_b4_change, timezone_b4, timezone_after, final_timezone
) {
  if (index_b4_change <= 0 || index_b4_change >= length(dates)) {
    stop(paste("Index is out of range. Index must be greater than 0",
      "and smaller than the length of the dataset"
    ))
  }
  dates_b4 <- lubridate::force_tz(
    dates[1:index_b4_change], tzone = timezone_b4
  )
  dates_after <- lubridate::force_tz(
    dates[(index_b4_change + 1):length(dates)], tzone = timezone_after
  )
  if (timezone_b4 != final_timezone) {
    dates_b4 <- as.POSIXct(
      dates_b4, tz = final_timezone
    )
  }
  if (timezone_after != final_timezone) {
    dates_after <- as.POSIXct(
      dates_after, tz = final_timezone
    )
  }
  c(dates_b4, dates_after)
}


#' Gets time change date for given month and year.
#'
#' @param month_int Integer representing month of time change.
#'  3 for March or 11 for November are the only accepted inputs.
#' @param year_int Year of time change date.
#' @return Time change date (char) in YYYY-MM-DD HH:MM:SS format.
#'  If time falls back, the hour for this date is the time immediately
#'  after falling back. If time jumps ahead, the hour for this date is the
#'  time immediately after jumping ahead.
get_time_change_date <- function(month_int, year_int) {
  days_char <- as.character(1:31)
  days_char[1:9] <- sprintf("0%s", 1:9)
  month_num_char <- as.character(month_int)
  if (month_num_char == "3") {
    month_num_char <- "03"
  }
  month_days <- sprintf("%s-%s-%s", year_int, month_num_char, days_char)

  if (month_int == 11) {
    month_days <- head(month_days, -1) # 30 days in Nov
    sundays <- month_days[which(weekdays(as.POSIXct(month_days)) == "Sunday")]
    sprintf("%s 01:00:00", sundays[[1]])
  } else if (month_int == 3) {
    sundays <- month_days[which(weekdays(as.POSIXct(month_days)) == "Sunday")]
    sprintf("%s 03:00:00", sundays[[2]])
  } else {
    stop("Month input must be for November or March")
  }
}


#' Sets timezone of dates to PST if data in a time change month.
#'  Sets timezone to either PST or PDT otherwise.
#'
#' @param dates Dates in POSIX format. If characters are read to
#'  POSIX times here, they must have YYYY-MM-DD HH:MM:SS format.
#'  Dates must have UTC timestamp even if they are in local time.
#' @param month_int Integer representing month.
#' @param year_int Integer representing year.
#' @param dates_in_utc Boolean representing if the dates are in UTC.
#'  Assumes dates are in local Vancouver time if false. Note that
#'  dates may be in local time even if POSIX timestamp is in UTC.
#' @return Dates (POSIX) in PST or PDT.
set_timezone_from_month <- function(
  dates, month_int, year_int, dates_in_utc
) {
  # Convert dates to local time if not in a time change month
  if (month_int != 3 && month_int != 11) {
    if (dates_in_utc) {
      dates <- as.POSIXct(dates, tz = "US/Pacific")
    } else {
      dates <- lubridate::force_tz(
        dates, tzone = "US/Pacific"
      )
    }
  } else {
    # Calculate local time change date
    time_change_date <- as.POSIXct(get_time_change_date(
      month_int, year_int
    ), tz = "UTC")
    final_timezone <- "Etc/GMT+8" # Set timezone to PST for time change months

    # Find index before time change occurs
    index_b4_change <- which( # RAMPs have data overlap at Nov time change
      dates[1:(length(dates) - 1)] > dates[2:length(dates)]
    )
    if (length(index_b4_change) == 0) { # QAQ have no overlap, overwrite data
      index_b4_change <- tail(which(dates < time_change_date), 1) #Bug if df dates not UTC
    }

    # Get timezones before and after time change
    # Adjust timezones and indices if no time change in data range
    if (dates_in_utc) { # Time change date irrelevant if dates are in UTC
      timezone_b4_change <- "UTC"
      timezone_after_change <- "UTC"
      index_b4_change <- 1
    } else if (month_int == 3) {
      timezone_b4_change <- "Etc/GMT+8"
      timezone_after_change <- "Etc/GMT+7"

      if (length(index_b4_change) == 0) {
        timezone_b4_change <- "Etc/GMT+7"
        timezone_after_change <- "Etc/GMT+7"
        index_b4_change <- 1
      } else if (index_b4_change == length(dates)) {
        timezone_b4_change <- "Etc/GMT+8"
        timezone_after_change <- "Etc/GMT+8"
        index_b4_change <- 1
      }
    } else { # November time change
      timezone_b4_change <- "Etc/GMT+7"
      timezone_after_change <- "Etc/GMT+8"

      if (length(index_b4_change) == 0) {
        timezone_b4_change <- "Etc/GMT+8"
        timezone_after_change <- "Etc/GMT+8"
        index_b4_change <- 1
      } else if (index_b4_change == length(dates)) {
        timezone_b4_change <- "Etc/GMT+7"
        timezone_after_change <- "Etc/GMT+7"
        index_b4_change <- 1
      }
    }
    dates <- shift_timezones_at_time_change(
      dates, index_b4_change, timezone_b4_change,
      timezone_after_change, final_timezone
    )
  }
}


#' Removes components of datset outside of start/end dates.
#'
#' @param dataset_df Dataframe of sensor data. Must have a column of
#'  dates with the column named date
#' @param start_date_char Start date (char) in YYYY-MM-DD HH:MM:SS format.
#'  Time portion can be omitted only if start date is at midnight.
#' @param end_date_char End date (char) in YYYY-MM-DD HH:MM:SS format.
#'  Time portion can be omitted only if end date is at midnight.
#' @return Dataset with out-of-range rows omitted.
remove_out_of_range_data <- function(
  dataset_df, start_date_char, end_date_char
) {
  timezone <- lubridate::tz(dataset_df$date)
  start_date <- as.POSIXct(start_date_char, tz = timezone)
  end_date <- as.POSIXct(end_date_char, tz = timezone)

  if (dataset_df$date[1] < start_date) {
    dataset_df <- dataset_df[-which(dataset_df$date < start_date), ]
  }
  if (dataset_df$date[length(dataset_df$date)] > end_date) {
    dataset_df <- dataset_df[-which(dataset_df$date > end_date), ]
  }
  dataset_df
}
