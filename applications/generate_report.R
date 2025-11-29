source("libraries/helper_functions.R")

generate_all_reports <- function(
  overall_report_folder_name,
  overall_photos_folder_name,
  overall_outdoor_data_folder,
  overall_indoor_data_folder,
  sensor_data,
  year_int,
  month_char,
  start_date_char,
  end_date_char,
  includes_time_change,
  outdoor_data_dfs, #NA if data from csv
  indoor_data_dfs #NA if data from csv
) {
  # Get time/date data
  month_num <- match(month_char, month.name)
  month_abbrev <- month.abb[month_num]
  if (month_num - 10 < 0) {
    month_num <- sprintf("0%s", month_num)
  }
  if (includes_time_change) {
    timezone <- "Etc/GMT+8"
  } else {
    timezone <- "US/Pacific"
  }

  # Define and create report folder
  report_folder <- file.path(
    overall_report_folder_name, sprintf("%s%s_reports", month_abbrev, year_int)
  )
  if (!(dir.exists(report_folder))) {
    dir.create(report_folder)
  }

  for (location in names(sensor_data)) {
    # Get location and sensor data
    location_data <- sensor_data[[location]]
    outdoor_sensor_id <- location_data[["outdoor_sensor_ID"]]
    indoor_sensor_id <- location_data[["indoor_sensor_ID"]]
    location_photo_file <- location_data[["photo_file_name"]]
    location_name_compressed <- gsub("_", "", location)

    # Get outdoor and indoor data
    if (is.na(outdoor_data_dfs[location]) && is.na(indoor_data_dfs[location])) {
      outdoor_data_file <- file.path(
        overall_outdoor_data_folder,
        sprintf("%s%s", month_char, year_int),
        sprintf("%s.csv", outdoor_sensor_id)
      )
      outdoor_data <- readr::read_csv(
        outdoor_data_file
      )
      outdoor_data$date <- lubridate::force_tz(
        outdoor_data$date, tzone = timezone
      )

      indoor_data_file <- file.path(
        overall_indoor_data_folder,
        sprintf("%s%s", month_char, year_int),
        sprintf("%s.csv", indoor_sensor_id)
      )
      indoor_data <- readr::read_csv(
        indoor_data_file
      )
      indoor_data$date <- lubridate::force_tz(
        indoor_data$date, tzone = timezone
      )
    } else {
      outdoor_data <- outdoor_data_dfs[[location]]
      indoor_data <- indoor_data_dfs[[location]]
    }

    if (is.null(outdoor_data) || is.null(indoor_data)) {
      print(sprintf(
        "Could not generate report for %s. Data for your time range may be unavailable from Git",
        gsub("_", " ", location)
      ))
    } else {
      # Generate report for each location in json file
      print(sprintf("Rendering report for %s", location))
      rmarkdown::render(
        input = "CCAS_report_generator.Rmd",
        output_format = "pdf_document",
        output_file = sprintf(
          "Report_%s_%s%s.pdf", location_name_compressed, month_abbrev, year_int
        ),
        output_dir = report_folder,
        params = list(
          year = year_int,
          month = month_char,
          location = chartr("_", " ", location),
          includes_time_change = includes_time_change,
          start_date_char = start_date_char,
          end_date_char = end_date_char,
          facility_photo_dir = file.path(
            overall_photos_folder_name, location_photo_file
          ),
          outdoor_dataset = outdoor_data,
          indoor_dataset = indoor_data
        ),
        clean = TRUE
      )
    }
  }
  unlink("*.log")
}

# If report generated from csvs, read csvs to get them to df
# Force tz to PST if time change, local time otherwise (for df from csv)
generate_one_report <- function(
  year_int,
  month_char,
  start_date_char,
  end_date_char,
  includes_time_change,
  facility_location_char,
  facility_photo_directory, # File inclusive
  outdoor_file_df,
  indoor_file_df,
  output_file_name,
  output_file_directory # File exclusive
) {
  rmarkdown::render(
    input = "CCAS_report_generator.Rmd",
    output_format = "pdf_document",
    output_file = output_file_name,
    output_dir = output_file_directory,
    params = list(
      year = year_int,
      month = month_char,
      location = chartr("_", " ", facility_location_char),
      includes_time_change = includes_time_change,
      start_date_char = start_date_char,
      end_date_char = end_date_char,
      facility_photo_dir = facility_photo_directory,
      outdoor_dataset = outdoor_file_df,
      indoor_dataset = indoor_file_df
    ),
    clean = TRUE
  )
  unlink("*.log") # Delete log files
}
# rmarkdown::render(
#   input = "CCAS_report_generator.Rmd",
#   output_format = "pdf_document",
#   output_file = "WV_TEST_Sept2025.pdf",
#   params = list(
#     year = 2025,
#     month = "September",
#     location = "West Vancouver Memorial Library",
#     facility_photo_dir = "facility_photos/WV_Library_Photo.png",
#     outdoor_file_dir = "outdoor_data_processed/September2025/2021.csv",
#     indoor_file_dir = "indoor_data_processed/September2025/2020_pred_2025_09_01.csv"
#   )
# )

# generate_all_reports(
#   "facility_reports", "facility_photos",
#   "outdoor_data_processed", "indoor_data_processed"
# )

# generate_one_report(
#   2025, "October", FALSE, "Squamish Nation Totem Hall",
#   "facility_photos/SquamishNationTotemHall_Photo.png",
#   "outdoor_data_processed/October2025/2032.csv",
#   "indoor_data_processed/October2025/2049.csv",
#   "Report_SquamishNationTotemHall_Oct2025",
#   "facility_reports/October2025"
# )

# generate_one_report(
#   2025, "October", FALSE, "Pemberton Community Centre",
#   "facility_photos/Pemberton_Photo.png",
#   "outdoor_data_processed/October2025/2042.csv",
#   "indoor_data_processed/October2025/2035.csv",
#   "Report_PembertonCommunityCentre_Oct2025",
#   "facility_reports/Oct2025_reports"
# )

# params <- list(
#   year = 2025,
#   month = "September",
#   includes_time_change = FALSE,
#   location = "Lions Gate Recreation Centre",
#   facility_photo_dir = "facility_photos/LionsGate_Photo.png",
#   outdoor_file_dir = "outdoor_data_processed/September2025/MOD-00632.csv",
#   indoor_file_dir = "indoor_data_processed/September2025/2029_pred_2025_09_01.csv"
# )
