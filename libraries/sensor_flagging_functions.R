# Assume data_df$date is in UTC posix
get_sensor_uptime <- function(
  data_df, target_start_date_char, target_end_date_char
) {
  first_expected_df_date <- as.POSIXct(target_start_date_char, tz = "UTC")
  last_expected_df_date <- as.POSIXct(
    target_end_date_char, tz = "UTC"
  ) + lubridate::days(1) - lubridate::minutes(15)

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

  # Get total number of expected dates and sensor uptime
  total_num_times <- nrow(data_df) + num_times_missed -
    length(post_outage_na_indices)
  (total_num_times - num_times_missed) / total_num_times
}