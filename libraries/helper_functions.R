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

# Generates unprocessed df from raw git urls of ALL sensors
# Df has repeat date ranges removed (except for time change overlap)
# TO BE REMOVED
get_df_from_calibrated_csvs <- function(raw_git_urls) {
  raw_data_df <- readr::read_csv(raw_git_urls, show_col_types = FALSE)
  print(length(raw_data_df$DATE))
  print("Read df")
  aqhi_current <- raw_data_df$AQHI[1:(length(raw_data_df$AQHI) - 1)]
  aqhi_next <- raw_data_df$AQHI[2:length(raw_data_df$AQHI)]
  print("Got AQHI vectors")

  repeated_data_start_indices <- c(
    1, ((which((is.na(aqhi_next)) & (!is.na(aqhi_current)))) + 1)
  )
  print(length(repeated_data_start_indices))
  # print(raw_data_df$DATE[repeated_data_start_indices])
  repeated_data_stop_indices <- which(diff(as.Date(raw_data_df$DATE)) != 0)
  print(length(repeated_data_stop_indices))
  # print(raw_data_df$DATE[repeated_data_stop_indices])
  print("Got repeated data start and stop indices")

  repeated_data_indices <- unlist(
    Map(`:`, repeated_data_start_indices, repeated_data_stop_indices)
  )
  print(length(repeated_data_indices))
  print("Got repeated date indices")

  raw_data_df[-repeated_data_indices, ] # Implicit return
}

# TODO: Don't save to csv in function, do in application
# Assumes date field is read as POSIX UTC but should be in local time
# TODO: make applications folder and move there
# TO BE REMOVED
process_calibrated_data_df <- function(
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
        dates, end_pdt_index, "Canada/Yukon",
        "Pacific/Pitcairn", "Pacific/Pitcairn"
      )
    } else if (month_int == 3) {
      end_pst_index <- tail(which(dates < time_change_date), 1)
      dates_pst <- shift_timezones_at_time_change(
        dates, end_pst_index, "Pacific/Pitcairn",
        "Canada/Yukon", "Pacific/Pitcairn"
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

# Processes outdoor files from github
# TODO: edit if you take indoor files from github
# TODO: modify to make more efficient- read_csv?
# Gets data without date overlaps
# Removes columns that aren't pollutants or AQHI
# Old algorithm, to be removed!!!
create_processed_csv <- function(
  raw_git_urls, data_includes_time_change,
  month_folder, is_outdoor_data
) {
  if (data_includes_time_change) {
    timezone <- "Pacific/Pitcairn" # Constant PST
  } else {
    timezone <- "US/Pacific" # Local time, PST or PDT
  }
  truncated_df_list <- list()

  for (url in raw_git_urls) {
    sensor_data <- tryCatch(
      read.csv(url),
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
  sensor_df <- bind_rows(truncated_df_list)

  # Select only pollutant level and AQHI data
  # NO not selected because no guidelines available
  pollutant_data <- sensor_df[c(
    "DATE", "CO", "NO2", "NO", "O3", "PM2.5", "CO2", "AQHI"
  )] 
  # Reformat date field
  colnames(pollutant_data)[[1]] <- "date" # timeAverage requires "date" field
  pollutant_data$date <- as.POSIXct(
    pollutant_data$date, format = "%Y-%m-%d %H:%M", tz = timezone
  )
  # Reformat PM2.5
  names(pollutant_data)[names(pollutant_data) == "PM2.5"] <- "PM2_5"

  # # Delete rows w/ NA (and rows w/o AQHI)
  # pollutant_data <- na.omit(pollutant_data)

  sensor_id <- sub(".*calibrated_data/(.*?)/.*", "\\1", url)
  if (is_outdoor_data) {
    location_folder <- "outdoor_data_processed"
  } else {
    location_folder <- "indoor_data_processed"
  }
  data_folder <- file.path(location_folder, month_folder)
  if (!(dir.exists(data_folder))) {
      dir.create(data_folder)
    }

  write.csv(
    pollutant_data,
    file.path(location_folder, month_folder, sprintf("%s.csv", sensor_id)),
    row.names = FALSE, quote = FALSE
  )
  return("Success!")
}

# To be removed when you remove non-metadata params
# Non-metadata params to be defined by user
extract_sensor_data_from_json <- function(json_file_dir) {
  sensor_metadata <- jsonlite::fromJSON(json_file_dir)
  includes_time_change <- sensor_metadata$includes_time_change
  month_char <- sensor_metadata$month
  year_int <- sensor_metadata$year

  fields_to_remove <- c("includes_time_change", "month", "year")
  sensor_metadata <- sensor_metadata[setdiff(
    names(sensor_metadata), fields_to_remove
  )]
  list(
    sensor_data = sensor_metadata,
    year_int = year_int,
    month_char = month_char,
    includes_time_change = includes_time_change
  )
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
      if (end_pdt_index == 0) { # QAQ have no overlap, data overwritten
        end_pdt_index <- tail(which(dates < time_change_date), 1)
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
  } # Processing if no time change occurs
  else {
    if (dates_in_UTC) {
      dates <- as.POSIXct(dates, tzone = "US/Pacific")
    } else {
      dates <- lubridate::force_tz(
        dates, tzone = "US/Pacific"
      )
    }
  }
  invisible(dates)
}

# Dates should mostly be for one month
# Dates from prev/next month acceptable if majority of dates from main month
# Dates that are not from main month treated same as main month
# TO BE REMOVED
set_timezone_from_dates <- function(
  dates, dates_in_UTC
) {
  nov_int <- 11
  mar_int <- 3

  # Get dominant month and year in dataset
  months_count <- table(lubridate::month(dates))
  month_int <- names(months_count)[which.max(months_count)] #Dominant month in dataset
  years_count <- table(lubridate::year(dates))
  year_int <- names(years_count)[which.max(years_count)] #Dominant year in dataset

  # November time change processing
  if (nov_int == month_int) {
    # Get Nov time change date
    time_change_date <- as.POSIXct(get_time_change_date(
      nov_int, year_int
    ), tz = "UTC")
    if (dates_in_UTC) {
      time_change_date <- time_change_date + lubridate::hours(7)
    }
    # Check if time change is within data range
    if (
      (dates[1] <= time_change_date) && (
        dates[length(dates)] >= time_change_date
      )
    ) {
      # Shift all times to PST
      end_pdt_index <- which( # RAMPs have data overlap
        dates[1:(length(dates) - 1)] > dates[2:length(dates)]
      )
      if (end_pdt_index == 0) { # QAQ have no overlap, data overwritten
        end_pdt_index <- tail(which(dates < time_change_date), 1)
      }
      if (dates_in_UTC) {
        print("Registered that dates are in UTC")
        dates <- shift_timezones_at_time_change(
          dates, end_pdt_index, "UTC",
          "UTC", "Etc/GMT+8"
        )
      } else {
        dates <- shift_timezones_at_time_change(
          dates, end_pdt_index, "Etc/GMT+7",
          "Etc/GMT+8", "Etc/GMT+8"
        )
      }
      return(dates)
    }
  } 
  # March time change processing
  else if (mar_int == month_int) {
    # Get Mar time change date
    time_change_date <- as.POSIXct(get_time_change_date(
      mar_int, year_int
    ), tz = "UTC")
    if (dates_in_UTC) {
      time_change_date <- time_change_date + lubridate::hours(8)
    }
    # Check if time change is within data range
    if (
      (dates[1] <= time_change_date) && (
        dates[length(dates)] >= time_change_date
      )
    ) {
      # Shift all times to PST
      end_pst_index <- tail(which(dates < time_change_date), 1)

      if (dates_in_UTC) {
        dates <- shift_timezones_at_time_change(
          dates, end_pdt_index, "UTC",
          "UTC", "Etc/GMT+8"
        )
      } else {
        dates <- shift_timezones_at_time_change(
          dates, end_pst_index, "Etc/GMT+8",
          "Etc/GMT+7", "Etc/GMT+8"
        )
      }
      return(dates)
    }
  }
  # Processing if no timezone occurs
  if (dates_in_UTC) {
    dates <- as.POSIXct(dates, tz = "US/Pacific")
  } else {
    dates <- lubridate::force_tz(
      dates, tzone = "US/Pacific"
    )
  }
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