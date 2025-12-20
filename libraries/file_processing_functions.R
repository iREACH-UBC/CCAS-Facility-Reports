#' Gets raw urls of calibrated sensor data files from Github.
#'
#' @param start_date Start date (char, in YYYY-MM-DD format) of data date range.
#' @param stop_date End date (char, in YYYY-MM-DD format) of data date range.
#' @param sensor_id Char or int of a sensor ID.
#' @return Raw git url (char). Returns one url or a vector of urls.
#' @export
get_raw_git_urls <- function(start_date, stop_date, sensor_id) {
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
    "main/calibrated_data/%s/%s_calibrated_%s_to_%s.csv"
  ), sensor_id, sensor_id, start_dates_char, end_dates_char)
}


#' Gets sensor data from raw git urls of calibrated data. Assumes empty
#'  csvs are published to Github for any days with no data.
#'
#' @param raw_git_urls Vector or list of raw git urls (char) for one sensor.
#' @return One dataframe with sensor data from git urls, if data available.
#'  If sensor data unavailable, returns NULL.
#' @export
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
  dplyr::bind_rows(truncated_df_list)
}


#' Gets sensor data from raw git urls of calibrated data. Assumes empty
#'  csvs are published to Github for any days with no data.
#'
#' @param start_date Start date (char, in YYYY-MM-DD format) of data date range.
#' @param stop_date End date (char, in YYYY-MM-DD format) of data date range.
#' @param sensor_id Char or int of a sensor ID.
#' @return One dataframe with sensor data from git urls, if data available.
#'  If sensor data unavailable, returns NULL.
#' @export
get_df_from_git_files <- function(
  start_date, stop_date, sensor_id
) {
  raw_urls <- get_raw_git_urls(start_date, stop_date, sensor_id)
  get_df_from_raw_git_urls(raw_urls)
}


#' Gets AQHI values given sensor data. Used for sensor dataframes
#'  missing an AQHI column.
#'
#' @param dataset A dataframe of calibrated sensor data. Must have
#'  date, NO2, O3, and PM2.5 columns.
#' @return Vector of AQHI values (int). Each index of the vector
#'  corresponds to a row in the dataset.
#' @export
get_aqhi_column <- function(dataset) {
  # Helper function that takes higher of two AQHI calculations
  apply_aqhi_ceiling <- function(aqhi_vec, pm25_1h_vec) {
    pmax(aqhi_vec, ceiling(pm25_1h_vec / 10)) |> round()
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


#' Saves processed sensor dataframe to a csv.
#' Csv is stored by location folder / month and year / sensor name.
#'
#' @param month_char Full month name the data is from.
#' @param year_int Year the data is from.
#' @param location_folder Outdoor or indoor data folder name.
#' @param processed_sensor_data_df Processed dataframe of sensor data.
#' @param timezone "US/Pacific" if no time change in data,
#'  "Etc/GMT+8" otherwise.
#' @param sensor_id Character or int denoting sensor ID.
#' @return A character of csv path.
#' @export
save_sensor_data_csv <- function(
  month_char, year_int, location_folder,
  processed_sensor_data_df, timezone,
  sensor_id
) {
  # Prepare csv destination
  month_folder <- sprintf("%s%s", month_char, year_int)
  data_destination <- file.path(location_folder, month_folder)
  if (!(dir.exists(data_destination))) {
    dir.create(data_destination)
  }
  # Save data to csv
  data.table::fwrite(
    transform(
      processed_sensor_data_df, date = format(date, tz = timezone)
    ), file.path(
      location_folder, month_folder, sprintf("%s.csv", sensor_id)
    )
  )
  file.path( # Return the csv path
    location_folder, month_folder, sprintf("%s.csv", sensor_id)
  )
}


#' Saves processed sensor dataframe to a csv.
#' Csv is stored by location folder / month and year / sensor name.
#'
#' @param dataset A dataframe with a column named date.
#' @param start_date_char Target start date (char, in YYYY-MM-DD format)
#'  of data date range.
#' @param end_date_char Target end date (char, in YYYY-MM-DD format)
#'  of data date range.
#' @param location_folder Outdoor or indoor data folder name.
#' @param processed_sensor_data_df Processed dataframe of sensor data.
#' @param timezone "US/Pacific" if no time change in data,
#'  "Etc/GMT+8" otherwise.
#' @param sensor_id Character or int denoting sensor ID.
#' @return A list where each component contains a dataframe (from the dataset)
#'  for a different day of the month. Dates without data contain a dataframe
#'  with no rows.
#' @export
separate_df_by_day <- function(
  dataset, start_date_char, end_date_char
) {
  start_date <- as.Date(start_date_char)
  end_date   <- as.Date(end_date_char)
  days <- seq(start_date, end_date, by = "day")

  daily_dfs <- lapply(
    days,
    function(d) dataset[as.Date(dataset$date) == d, ]
  )
  names(daily_dfs) <- as.character(days)
  daily_dfs
}
