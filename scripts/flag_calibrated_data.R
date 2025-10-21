library(readr)
source("libraries/flagging_functions.R")

# Start adjustable parameters
month_char <- "September"
year_int <- 2025
# End adjustable parameters

if (month_char == "November" || month_char == "March") {
  timezone <- "Pacific/Pitcairn" # Constant PST
} else {
  timezone <- "US/Pacific" # Local time, PST or PDT
}
month_int <- match(month_char, month.name)
month_folder <- sprintf("%s%s", month_char, year_int)

# Get all CSV files in a folder
outdoor_files <- list.files(
  path = file.path("outdoor_data_processed", month_folder),
  pattern = "\\.csv$", full.names = TRUE
)
indoor_files <- list.files(
  path = file.path("indoor_data_processed", month_folder),
  pattern = "\\.csv$", full.names = TRUE
)

# Read each file into a list of dataframes
outdoor_df_list <- lapply(outdoor_files, read_csv)
indoor_df_list <- lapply(indoor_files, read_csv)

# TODO: Change indoor names if file format changes
names(outdoor_df_list) <- tools::file_path_sans_ext(basename(outdoor_files))
indoor_file_names <- tools::file_path_sans_ext(basename(indoor_files))
names(indoor_df_list) <- sub("_pred.*", "\\1", indoor_file_names)

# Process outdoor data dates
for (name in names(outdoor_df_list)) {
  # Add midnight to date if missing
  outdoor_df_list[[name]]$date <- ifelse(
    grepl(":", outdoor_df_list[[name]]$date),
    outdoor_df_list[[name]]$date,
    paste0(outdoor_df_list[[name]]$date, " 00:00:00")
  )
  outdoor_df_list[[name]]$date <- as.POSIXct(
    outdoor_df_list[[name]]$date,
    format = "%Y-%m-%d %H:%M", #Neglect seconds
    tz = timezone
  )
}

# Process indoor data dates
for (name in names(indoor_df_list)) {
  # Add midnight to date if missing
  indoor_df_list[[name]]$date <- ifelse(
    grepl(":", indoor_df_list[[name]]$date),
    indoor_df_list[[name]]$date,
    paste0(indoor_df_list[[name]]$date, " 00:00:00")
  )
  indoor_df_list[[name]]$date <- as.POSIXct(
    indoor_df_list[[name]]$date,
    format = "%Y-%m-%d %H:%M" #Neglect seconds
  )
  # Convert indoor data to local time
  indoor_df_list[[name]]$date <- as.POSIXct(
    indoor_df_list[[name]]$date,
    tz = timezone
  )
}

# Combine indoor and outdoor lists
calibrated_data_dfs <- c(outdoor_df_list, indoor_df_list)

# Flag NA values
flags <- data.frame(
  sensor_id = character(),
  file_date = character(),
  flag = character(),
  decription = character(),
  stringsAsFactors = FALSE
)
flags_for_na <- flag_na_readings(
  all_sensor_dfs = calibrated_data_dfs,
  flags_df = flags,
  month_int = month_int,
  year_int = year_int
)

# Remove rows with NAs
calibrated_data_dfs <- na.omit(calibrated_data_dfs)

# Flag AQ objective exceedances
# TODO: check if this takes time average of df list as expected
sensor_data_1hr_avg <- openair::timeAverage(
  calibrated_data_dfs, avg.time = "hour"
)
sensor_data_24hr_avg <- openair::timeAverage(
  calibrated_data_dfs, avg.time = "day"
)
