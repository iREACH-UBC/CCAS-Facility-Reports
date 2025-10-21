library(dplyr)

add_flag <- function(
  sensor_ids, file_dates, flags, descriptions, flags_df
) {
  new_flag <- data.frame(
    sensor_id = sensor_ids,
    file_date = file_dates,
    flag = flags,
    decription = descriptions
  )
  flags_df <- bind_rows(flags_df, new_flag)
  return(flags_df)
}

flag_na_readings <- function(
  all_sensor_dfs, flags_df, month_int, year_int
) {
  # Flag NAs in file
  for (name in names(all_sensor_dfs)) {
    if (anyNA(all_sensor_dfs[[name]])) {
      na_indices <- which(is.na(all_sensor_dfs[[name]]))
      num_na <- sum(na_indices)
      first_na_index <- na_indices[1]
      last_na_index <- tail(na_indices, 1)

      flags_df <- add_flag(
        sensor_ids = name,
        file_dates = sprintf("%s/%s", month_int, year_int),
        flags = "sensor",
        descriptions = sprintf(
          "%s NAs found in calibrated data, starting at %s and ending at %s",
          num_na,
          all_sensor_dfs[[name]]$date[[first_na_index]],
          all_sensor_dfs[[name]]$date[[last_na_index]],
        ),
        flags_df = flags_df
      )
    }
  }
  return(flags_df)
}

flag_aq_objective_exceedance <- function(
  all_sensor_dfs, flags_df
) {
  
}