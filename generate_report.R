source("libraries/helper_functions.R")

generate_all_reports <- function(
  overall_report_folder_name,
  overall_photos_folder_name,
  overall_outdoor_data_folder,
  overall_indoor_data_folder
) {
  sensor_parameters <- extract_sensor_data_from_json(
    "sensor_data.json"
  )
  sensor_metadata <- sensor_parameters[["sensor_data"]]
  year_int <- sensor_parameters[["year_int"]]
  month_char <- sensor_parameters[["month_char"]]
  includes_time_change <- sensor_parameters[["includes_time_change"]]

  month_num <- match(month_char, month.name)
  month_abbrev <- month.abb[month_num]
  if (month_num - 10 < 0) {
    month_num <- sprintf("0%s", month_num)
  }

  report_folder <- file.path(
    overall_report_folder_name, sprintf("%s%s_reports", month_abbrev, year_int)
  )
  if (!(dir.exists(report_folder))) {
    dir.create(report_folder)
  }

  for (location in names(sensor_metadata)) {
    location_data <- sensor_metadata[[location]]
    outdoor_sensor_id <- location_data[["outdoor_sensor_ID"]]
    indoor_sensor_id <- location_data[["indoor_sensor_ID"]]
    location_photo_file <- location_data[["photo_file_name"]]
    location_name_compressed <- gsub("_", "", location)

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
        facility_photo_dir = file.path(
          overall_photos_folder_name, location_photo_file
        ),
        outdoor_file_dir = file.path(
          overall_outdoor_data_folder,
          sprintf("%s%s", month_char, year_int),
          sprintf("%s.csv", outdoor_sensor_id)
        ),
        indoor_file_dir = file.path(
          overall_indoor_data_folder,
          sprintf("%s%s", month_char, year_int),
          sprintf("%s.csv", indoor_sensor_id)
        )
      ),
      clean = TRUE
    )
  }
  unlink("*.log")
}


generate_one_report <- function(
  year_int,
  month_char,
  includes_time_change,
  facility_location_char,
  facility_photo_directory, # File inclusive
  outdoor_file_directory, # File inclusive
  indoor_file_directory, # File inclusive
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
      location = facility_location_char,
      includes_time_change = includes_time_change,
      facility_photo_dir = facility_photo_directory,
      outdoor_file_dir = outdoor_file_directory,
      indoor_file_dir = indoor_file_directory
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

generate_all_reports(
  "facility_reports", "facility_photos",
  "outdoor_data_processed", "indoor_data_processed"
)

# generate_one_report(
#   2025, "September", FALSE, "Capilano Library",
#   "facility_photos/Capilano_Photo.png",
#   "outdoor_data_processed/September2025/MOD-00631.csv",
#   "indoor_data_processed/September2025/MOD-00618_pred_2025_09_01.csv",
#   "Capilano_NA_removed_file", NULL
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
