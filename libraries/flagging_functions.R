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
}

flag_na_readings <- function(
  all_sensor_dfs, flags_df, month_int, year_int
) {
  # Flag NAs in file
  for (name in names(all_sensor_dfs)) {
    if (anyNA(all_sensor_dfs[[name]])) {
      na_row_indices <- which(apply(
        all_sensor_dfs[[name]], 1, function(row) any(is.na(row))
      ))
      num_na <- sum((is.na(all_sensor_dfs[[name]])))
      first_na_index <- na_row_indices[1]
      last_na_index <- tail(na_row_indices, 1)

      flags_df <- add_flag(
        sensor_ids = name,
        file_dates = all_sensor_dfs[[name]]$date[[first_na_index]], #First date
        flags = "sensor",
        descriptions = sprintf(
          "%s NA(s) found in calibrated data, starting at %s and ending at %s",
          num_na,
          all_sensor_dfs[[name]]$date[[first_na_index]],
          all_sensor_dfs[[name]]$date[[last_na_index]]
        ),
        flags_df = flags_df
      )
    }
  }
}

flag_negative_values <- function(
  all_sensor_dfs, flags_df, month_int, year_int
) {
  for (name in names(all_sensor_dfs)) {
    if (any(all_sensor_dfs[[name]] < 0)) {
      df_without_dates <- all_sensor_dfs[[name]][,
        names(all_sensor_dfs[[name]]) != "date"
      ]
      negatives_per_pollutant <- colSums(df_without_dates < 0, na.rm = TRUE)
      row_indices_of_negatives <- which(apply(
        df_without_dates, 1, function(row) any(row < 0)
      ))
      first_negative_index <- row_indices_of_negatives[1]
      last_negative_index <- tail(row_indices_of_negatives, 1)

      flags_df <- add_flag(
        sensor_ids = name,
        file_dates = all_sensor_dfs[[name]]$date[[first_negative_index]], #First date
        flags = "sensor",
        description = sprintf(paste0(
          "%s negative value(s) in dataset, ",
          "starting at %s and ending at %s. %s belonged to %s."),
          sum(negatives_per_pollutant),
          all_sensor_dfs[[name]]$date[[first_negative_index]],
          all_sensor_dfs[[name]]$date[[last_negative_index]],
          max(negatives_per_pollutant),
          names(which.max(negatives_per_pollutant))
        ),
        flags_df = flags_df
      )
    }
  }
}

# Take daily and hourly average once in flag script
# Assumes 
flag_aq_objective_exceedance <- function(
  sensor_dfs_hr_avg, sensor_dfs_day_avg, flags_df
) {
  # Flagging metrics
  max_avg_1hr_no2_ppb <- 42
  max_avg_24hr_pm2_5_ug_per_m3 <- 25
  max_avg_1hr_co_ppm <- 13
  max_avg_24hr_co2_ppm <- 1000
  max_avg_1hr_o3_ppb <- 82
  high_aqhi_index <- 7

  # Find if this happens in your dfs, record date(s) it happened, sensor id, description
  # Way to do without for loop? No- need to do one df at a time to compile all dates in description
  for (name in names(sensor_dfs_hr_avg)) {
    flags_df <- add_aq_objectives_flag(
      aq_metric = max_avg_1hr_no2_ppb, pollutant = "NO2",
      sensor_dataset = sensor_dfs_hr_avg[[name]],
      sensor_id = name, all_flags_df = flags_df
    ) |> add_aq_objectives_flag(
      aq_metric = max_avg_24hr_pm2_5_ug_per_m3, pollutant = "PM2_5",
      sensor_dataset = sensor_dfs_day_avg[[name]],
      sensor_id = name, all_flags_df = _
    ) |> add_aq_objectives_flag(
      aq_metric = max_avg_1hr_co_ppm, pollutant = "CO",
      sensor_dataset = sensor_dfs_hr_avg[[name]],
      sensor_id = name, all_flags_df = _
    ) |> add_aq_objectives_flag(
      aq_metric = max_avg_24hr_co2_ppm, pollutant = "CO2",
      sensor_dataset = sensor_dfs_day_avg[[name]],
      sensor_id = name, all_flags_df = _
    ) |> add_aq_objectives_flag(
      aq_metric = max_avg_1hr_o3_ppb, pollutant = "O3",
      sensor_dataset = sensor_dfs_hr_avg[[name]],
      sensor_id = name, all_flags_df = _
    ) |> add_aq_objectives_flag(
      aq_metric = high_aqhi_index, pollutant = "AQHI",
      sensor_dataset = sensor_dfs_hr_avg[[name]],
      sensor_id = name, all_flags_df = _
    )
  }
  return(flags_df)
}

# TODO: check if this works (may not be able to have inhomogeneous df)
add_aq_objectives_flag <- function(
  aq_metric, pollutant, sensor_dataset, sensor_id, all_flags_df
) {
  pollutant_exceedance <- sensor_dataset[[pollutant]] > aq_metric
  if (any(pollutant_exceedance)) {
    exceedance_indices <- which(pollutant_exceedance)
    exceedance_dates <- sensor_dataset$date[exceedance_indices]
    all_flags_df <- add_flag(
      sensor_ids = sensor_id, file_dates = exceedance_dates,
      flags = pollutant,
      descriptions = sprintf("%s air quality objective exceedance", pollutant),
      flags_df = all_flags_df
    )
  }
  return(all_flags_df)
}