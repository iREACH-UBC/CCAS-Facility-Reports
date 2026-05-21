library(dplyr)

#Parameters
base_path <- "C:\\Users\\jaspe\\OneDrive\\Documents\\lcs-calibrated-data"
target_month <- "2026-04"

#daily and monthly paths
daily_base <- file.path(base_path, "daily")
monthly_base <- file.path(base_path, "monthly")

#Get sensor folders
sensor_folders <- list.dirs(
  path = daily_base,
  recursive = FALSE,
  full.names = TRUE
)

#loop through sensor folders
for (sensor_path in sensor_folders) {
  
  #Sensor name
  sensor_name <- basename(sensor_path)
  
  #Path to month folder (w/ daily csv's)
  month_path <- file.path(sensor_path, target_month)
  
  #no month folder escape
  if (!dir.exists(month_path)) {
    cat("Skipped missing:", month_path, "\n")
    next
  }
  
  #make list of csv's
  csv_files <- list.files(
    path = month_path,
    pattern = "\\.csv$",
    full.names = TRUE
  )
  
  #no csv's within month folder escape
  if (length(csv_files) == 0) {
    cat("No CSV in:", month_path, "\n")
    next
  }
  
  #create var with combined data from each file
  combined_data <- bind_rows(
    lapply(csv_files, function(file) {
      read.csv(file, header = TRUE)
    })
  )
  
  #Output folder
  monthly_folder <- file.path(monthly_base, sensor_name)
  
  #File name
  month_for_filename <- gsub("-", "_", target_month)
  
  month_file_name <- file.path(
    monthly_folder,
    paste0(sensor_name, "_", month_for_filename, ".csv")
  )
  
  #write
  write.csv(
    combined_data,
    month_file_name,
    row.names = FALSE
  )
  
  cat("Done:", month_path)
  
}
