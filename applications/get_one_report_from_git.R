# Gets outdoor and indoor data from Git and saves them to csvs.
# Generates report with this data if available from Github.

source("applications/report_automation.R")

# Start user adjustable parameters
month_char <- "October"
year_int <- 2025
start_date_char_outdoors <- "2025-10-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_outdoors <- "2025-10-31 23:45:00" # YYYY-MM-DD HH:MM:SS
start_date_char_indoors <- "2025-10-01 00:00:00" # YYYY-MM-DD HH:MM:SS
end_date_char_indoors <- "2025-10-31 23:45:00" # YYYY-MM-DD HH:MM:SS
outdoor_sensor_id <- 2040
indoor_sensor_id <- 2044
location <- "Gillies_Bay_Public_Library" # Matches name in sensor json
# End user adjustable parameters

month_int <- match(month_char, month.name)
month_abbrev <- month.abb[month_int]

get_report_from_git_csvs(
  start_date_char_outdoors = start_date_char_outdoors,
  end_date_char_outdoors = end_date_char_outdoors,
  start_date_char_indoors = start_date_char_indoors,
  end_date_char_indoors = end_date_char_indoors,
  outdoor_sensor_id = outdoor_sensor_id,
  indoor_sensor_id = indoor_sensor_id,
  location = location,
  facility_photo_directory = "facility_photos/GilliesBay_Photo.png",
  month_char = month_char,
  year_int = year_int,
  outdoor_csv_folder = "test_pipeline_outdoor3", # Change
  indoor_csv_folder = "test_pipeline_indoor3", # Change
  report_folder_directory = file.path("test_pipeline_reports3",
    sprintf("%s%s_reports", month_abbrev, year_int)) # Change
)