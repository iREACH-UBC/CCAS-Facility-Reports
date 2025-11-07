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