library(readr)
source("prototypes/flagging_functions.R")

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
# Assumes naming convention of only sensor ID 
names(outdoor_df_list) <- tools::file_path_sans_ext(basename(outdoor_files))
names(indoor_df_list) <- tools::file_path_sans_ext(basename(indoor_files))
# indoor_file_names <- tools::file_path_sans_ext(basename(indoor_files))
# names(indoor_df_list) <- sub("_pred.*", "\\1", indoor_file_names)

# Combine indoor and outdoor lists
calibrated_data_dfs <- c(outdoor_df_list, indoor_df_list)

# Assumes both indoor and outdoor data are in local time
# No need to add midnight if missing (using read_csv)
for (name in names(calibrated_data_dfs)) {
  calibrated_data_dfs[[name]]$date <- lubridate::force_tz(
    calibrated_data_dfs[[name]]$date, tz = timezone
  )
}
# # Process indoor data dates
# # No need to add midnight if missing (using read_csv)
# for (name in names(indoor_df_list)) {
#   # Convert indoor data to local time
#   indoor_df_list[[name]]$date <- as.POSIXct(
#     indoor_df_list[[name]]$date,
#     tz = timezone
#   )
# }

# Flag and remove NAs
flags <- data.frame(
  sensor_id = character(),
  file_date = character(),
  flag = character(),
  decription = character(),
  stringsAsFactors = FALSE
)
na_flags <- flag_na_readings(
  all_sensor_dfs = calibrated_data_dfs,
  flags_df = flags,
  month_int = month_int,
  year_int = year_int
)
calibrated_data_dfs <- lapply(calibrated_data_dfs, function(x) na.omit(x))

# Flag and replace negative values with 0
sensor_flags <- flag_negative_values(
  all_sensor_dfs = calibrated_data_dfs,
  flags_df = na_flags,
  month_int = month_int,
  year_int = year_int
)
calibrated_data_dfs <- lapply(
  calibrated_data_dfs, function(x) {x[x < 0] <- 0; x}
)

# Flag AQ objective exceedances
sensor_data_1hr_avg <- lapply(
  calibrated_data_dfs,
  function(df) openair::timeAverage(
    df, avg.time = "hour"
  )
)
sensor_data_24hr_avg <- lapply(
  calibrated_data_dfs,
  function(df) openair::timeAverage(
    df, avg.time = "day"
  )
)

