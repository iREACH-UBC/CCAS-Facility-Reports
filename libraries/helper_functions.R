library(dplyr)

# Start and stop inclusive
# Dates in "YYYY-MM-DD" format
# sensor_id can be a char (ex. "2021") or number (ex. 2021)
get_file_urls <- function(start_date, stop_date, sensor_id) {
  start_date <- as.Date(start_date)
  stop_date <- as.Date(stop_date)

  file_end_dates_numeric <- as.numeric(start_date):as.numeric(stop_date)
  file_start_dates_numeric <- file_end_dates_numeric - 2

  end_dates <- as.Date(file_end_dates_numeric, origin = "1970-01-01")
  start_dates <- as.Date(file_start_dates_numeric, origin = "1970-01-01")

  end_dates_char <- as.character(gsub("-", "_", end_dates))
  start_dates_char <- as.character(gsub("-", "_", start_dates))

  return(sprintf(paste0(
  "https://raw.githubusercontent.com/iREACH-UBC/CCAS_Dashboard/refs/heads/",
  "main/calibrated_data/%s/%s_calibrated_%s_to_%s.csv"),
  sensor_id, sensor_id, start_dates_char, end_dates_char))
}

# Generates unprocessed df from raw git urls
# Df has repeat date ranges removed
# TODO- edit so it doesn't remove data overlap during time change for RAMP
# Look for start indices of blank AQHI entries, stop at next day
get_df_from_calibrated_csvs <- function(raw_git_urls) {
  raw_data_df <- readr::read_csv(raw_git_urls)
  dates_current <- raw_data_df$DATE[1:(length(raw_data_df$DATE) - 1)]
  dates_next <- raw_data_df$DATE[2:length(raw_data_df$DATE)]

  repeated_dates_start_indices <- c(1, (which(dates_current > dates_next) + 1))
  repeated_dates_stop_indices <- which(diff(as.Date(raw_data_df$DATE)) != 0) + 1
  repeated_dates_indices <- unlist(
    Map(`:`, repeated_dates_start_indices, repeated_dates_stop_indices)
  )
  raw_data_df[-repeated_dates_indices, ] # Implicit return
}

# TODO: Don't save to csv in function, do in application
# Assumes date field is read as POSIX UTC but should be in local time
# TODO: make applications folder and move there
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
  dates <- calibrated_dataset_df$date
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
}

# Assumes UTC POSIX dates
# Timezone b4 and after are different (ex. PST and PDT)
# Final timezone is either the timezone b4 or after
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
  } else if (timezone_after != final_timezone) {
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

# Processes outdoor files from github
# TODO: edit if you take indoor files from github
# TODO: modify to make more efficient- read_csv?
# Gets data without date overlaps
# Removes columns that aren't pollutants or AQHI
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
    sensor_data <- read.csv(url)
    target_date_unformatted <- sub(".*to_(.*?).csv.*", "\\1", url)
    target_date <- gsub("_", "-", target_date_unformatted)

    # Get index of first occurrence
    first_index <- grep(target_date, sensor_data$DATE)[1]

    # Get subset of nested list
    one_day_list <- lapply(sensor_data, function(x) x[first_index:length(sensor_data$DATE)])
    truncated_df_list[[length(truncated_df_list) + 1]] <- as.data.frame(one_day_list)
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
  write.csv(
    pollutant_data,
    file.path(location_folder, month_folder, sprintf("%s.csv", sensor_id)),
    row.names = FALSE, quote = FALSE
  )
}

extract_sensor_data_from_json <- function(json_file_dir) {
  sensor_metadata <- jsonlite::fromJSON(json_file_dir)
  includes_time_change <- sensor_metadata$includes_time_change
  month_char <- sensor_metadata$month
  year_int <- sensor_metadata$year

  fields_to_remove <- c("includes_time_change", "month", "year")
  sensor_metadata <- sensor_metadata[setdiff(
    names(sensor_metadata), fields_to_remove
  )]
  return(list(
    sensor_data = sensor_metadata,
    year_int = year_int,
    month_char = month_char,
    includes_time_change = includes_time_change
  ))
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