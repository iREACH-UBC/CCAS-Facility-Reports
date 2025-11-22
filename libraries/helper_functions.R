library(dplyr)

# Start and stop inclusive
# Dates in "YYYY-MM-DD" format
# sensor_id can be a char (ex. "2021") or number (ex. 2021)
# Call on one sensor id at a time to avoid unexpected urls
get_file_urls <- function(start_date, stop_date, sensor_id) {
  start_date <- as.Date(start_date)
  stop_date <- as.Date(stop_date)

  file_end_dates_numeric <- as.numeric(start_date):as.numeric(stop_date)
  file_start_dates_numeric <- file_end_dates_numeric - 2

  end_dates <- as.Date(file_end_dates_numeric, origin = "1970-01-01")
  start_dates <- as.Date(file_start_dates_numeric, origin = "1970-01-01")

  end_dates_char <- as.character(gsub("-", "_", end_dates))
  start_dates_char <- as.character(gsub("-", "_", start_dates))

  sprintf(paste0(
    "https://raw.githubusercontent.com/iREACH-UBC/CCAS_Dashboard/refs/heads/",
  "main/calibrated_data/%s/%s_calibrated_%s_to_%s.csv"),
  sensor_id, sensor_id, start_dates_char, end_dates_char)
}

# Year and sensor id can be char or int, month_num must be int
get_month_start_end_dates <- function(month_int, year) {
  month_num_char <- as.character(month_int)
  if (month_int - 10 < 0) {
    month_num_char <- sprintf("0%s", month_int)
  }
  start_date <- sprintf("%s-%s-01", year, month_num_char)
  month_abbrev <- month.abb[month_int]
  days_in_month <- lubridate::days_in_month(
    lubridate::ymd(start_date)
  )[[month_abbrev]]
  end_date <- sprintf("%s-%s-%s", year, month_num_char, days_in_month)

  list("month_start_date" = start_date, "month_end_date" = end_date)
}


# Assumes POSIX dates
# Timezone b4 and after are timezones before/after time change
# Final timezone is the timezone you are converting dates to
shift_timezones_at_time_change <- function(
  dates, index_b4_change, timezone_b4, timezone_after, final_timezone
) {
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

# Given year and month (Nov or Mar), get time change date for month
# Returns char of date in YYYY-MM-DD HH:MM:SS format
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

get_df_from_raw_git_urls <- function(raw_git_urls) {
  truncated_df_list <- list()

  for (url in raw_git_urls) {
    sensor_data <- tryCatch(
      readr::read_csv(url, show_col_types = FALSE),
      error = function(e) {
        message("Could not read file: ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(sensor_data)) {
      return(NULL)
    }
    target_date_unformatted <- sub(".*to_(.*?).csv.*", "\\1", url)
    target_date <- gsub("_", "-", target_date_unformatted)

    # Get index of first occurrence
    first_index <- grep(target_date, sensor_data$DATE)[1]

    # Get subset of nested list if target dates found
    if (!(is.na(first_index))) {
      one_day_list <- lapply(
        sensor_data, function(x) x[first_index:length(sensor_data$DATE)]
      )
      truncated_df_list[[
        length(truncated_df_list) + 1
      ]] <- as.data.frame(one_day_list)
    }
  }
  bind_rows(truncated_df_list)
}


get_aqhi_column <- function(dataset){
  # Helper function that takes higher of two AQHI calculations
  apply_aqhi_ceiling <- function(aqhi_vec, pm25_1h_vec) {
    pmax(round(aqhi_vec), ceiling(pm25_1h_vec / 10)) |> as.integer()
  }
  # Take pollutant and PM averages
  NO2_3h   <- zoo::rollapply(
    dataset$NO2,   12, mean, fill = NA, align = "right", na.rm = TRUE
  )
  O3_3h    <- zoo::rollapply(
    dataset$O3,    12, mean, fill = NA, align = "right", na.rm = TRUE
  )
  PM2_5_3h <- zoo::rollapply(
    dataset$PM2_5, 12, mean, fill = NA, align = "right", na.rm = TRUE
  )
  PM2_5_1h <- zoo::rollapply(
    dataset$PM2_5,  4, mean, fill = NA, align = "right", na.rm = TRUE
  )
  # Calculate AQHI
  aqhi_val <- (10 / 10.4) * 100 * (
    (exp(0.000871 * NO2_3h) - 1) +
    (exp(0.000537 * O3_3h) - 1) +
    (exp(0.000487 * PM2_5_3h) - 1)
  )
  invisible(mapply(apply_aqhi_ceiling, aqhi_val, PM2_5_1h))
}

# Sets time to PST if includes time change, PST or PDT otherwise
# data_includes_time_change is true if both:
#   1. dates includes a time change
#   2. the time change is in your month of interest (month_int)
# Assumes dates are in local time unless dates_in_UTC is true
set_timezone_from_month <- function(
  dates, data_includes_time_change, month_int,
  year_int, dates_in_UTC
) {
  # Calculate local time change date if time change occurs
  if (data_includes_time_change) {
    time_change_date <- as.POSIXct(get_time_change_date(
      month_int, year_int
    ), tz = "UTC")

    # November timezone processing
    if (month_int == 11) {
      if (dates_in_UTC) {
        time_change_date <- time_change_date + lubridate::hours(7)
      }
      end_pdt_index <- which( # RAMPs have data overlap
        dates[1:(length(dates) - 1)] > dates[2:length(dates)]
      )
      if (length(end_pdt_index) == 0) { # QAQ have no overlap, data overwritten
        end_pdt_index <- tail(which(dates < time_change_date), 1)
      }
      if (length(end_pdt_index) == 0) {
        stop(paste(
          "Incorrect function argument to set_timezone_from_month,",
          "data does NOT include a time change"
        ))
      }
      if (dates_in_UTC) {
        dates <- shift_timezones_at_time_change(
          dates, end_pdt_index, "UTC", "UTC", "Etc/GMT+8"
        )
      } else {
        dates <- shift_timezones_at_time_change(
          dates, end_pdt_index, "Etc/GMT+7",
          "Etc/GMT+8", "Etc/GMT+8"
        )
      }
    }
    # March timezone processing
    else if (month_int == 3) {
      if (dates_in_UTC) {
        time_change_date <- time_change_date + lubridate::hours(8)
      }
      end_pst_index <- tail(which(dates < time_change_date), 1)
      if (end_pst_index == length(dates)) {
        stop(paste(
          "Incorrect function argument to set_timezone_from_month,",
          "data does NOT include a time change"
        ))
      }
      if (dates_in_UTC) {
        dates <- shift_timezones_at_time_change(
          dates, end_pst_index, "UTC", "UTC", "Etc/GMT+8"
        )
      } else {
        dates <- shift_timezones_at_time_change(
          dates, end_pst_index, "Etc/GMT+8",
          "Etc/GMT+7", "Etc/GMT+8"
        )
      }
    }
  } else { # Processing if no time change occurs
    if (dates_in_UTC) {
      dates <- as.POSIXct(dates, tz = "US/Pacific")
    } else {
      dates <- lubridate::force_tz(
        dates, tzone = "US/Pacific"
      )
    }
  }
  invisible(dates)
}


# Start and end date in YYYY-MM-DD format
# Remove components of datset outside of start/end dates
remove_out_of_range_data <- function(
  dataset_df, timezone, start_date_char, end_date_char
) {
  start_date <- as.POSIXct(start_date_char, tz = timezone)
  end_date <- as.POSIXct(end_date_char, tz = timezone)
  date_after_end <- end_date + lubridate::days(1)

  if (dataset_df$date[1] < start_date) {
    dataset_df <- dataset_df[-which(dataset_df$date < start_date), ]
  }
  if (dataset_df$date[length(dataset_df$date)] >= date_after_end) {
    dataset_df <- dataset_df[-which(dataset_df$date >= date_after_end), ]
  }
  dataset_df
}


# Returns true if time range includes time change
# Assumes start and end date are in local time
# Start and end date in YYYY-MM-DD format
data_includes_time_change <- function(
  month_int, start_date_char, end_date_char, year_int
) {
  nov_int <- 11
  mar_int <- 3
  start_date <- as.POSIXct(start_date_char, tz = "UTC")
  end_date <- as.POSIXct(end_date_char, tz = "UTC")

  if (month_int == nov_int) {
    # Get Nov time change date
    time_change_date <- as.POSIXct(get_time_change_date(
      nov_int, year_int
    ), tz = "UTC")
    # Check if time change is within data range
    if (
      (start_date <= time_change_date) && (
        end_date >= time_change_date
      )
    ) {
      return(TRUE)
    }
  } else if (month_int == mar_int) {
    # Get Mar time change date
    time_change_date <- as.POSIXct(get_time_change_date(
      mar_int, year_int
    ), tz = "UTC")
    # Check if time change is within data range
    if (
      (start_date <= time_change_date) && (
        end_date >= time_change_date
      )
    ) {
      return(TRUE)
    }
  }
  FALSE
}


# times <- c(
#   "2025-11-02 00:00:00",
#   "2025-11-02 00:15:00",
#   "2025-11-02 00:30:00",
#   "2025-11-02 00:45:00",
#   "2025-11-02 01:00:00",
#   "2025-11-02 01:15:00",
#   "2025-11-02 01:30:00",
#   "2025-11-02 01:45:00",
#   "2025-11-02 01:00:00",
#   "2025-11-02 01:15:00",
#   "2025-11-02 01:30:00",
#   "2025-11-02 01:45:00",
#   "2025-11-02 02:00:00",
#   "2025-11-02 02:15:00",
#   "2025-11-02 02:30:00",
#   "2025-11-02 02:45:00",
#   "2025-11-02 03:00:00"
# )
# times <- c(
#   "2025-11-03 00:00:00",
#   "2025-11-03 00:15:00",
#   "2025-11-03 00:30:00",
#   "2025-11-03 00:45:00",
#   "2025-11-03 01:00:00",
#   "2025-11-03 01:15:00",
#   "2025-11-03 01:30:00",
#   "2025-11-03 01:45:00",
#   "2025-11-03 01:00:00",
#   "2025-11-03 01:15:00",
#   "2025-11-03 01:30:00",
#   "2025-11-03 01:45:00",
#   "2025-11-03 02:00:00",
#   "2025-11-03 02:15:00",
#   "2025-11-03 02:30:00",
#   "2025-11-03 02:45:00",
#   "2025-11-03 03:00:00"
# )