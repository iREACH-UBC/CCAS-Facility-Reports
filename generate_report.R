library(jsonlite)

sensor_metadata <- jsonlite::fromJSON("sensor_data.json")
includes_time_change <- sensor_metadata$includes_time_change
month_char <- sensor_metadata$month
month_num <- match(month_char, month.name)
month_abbrev <- month.abb[month_num]
year_int <- sensor_metadata$year

if (month_num - 10 < 0) {
  month_num <- sprintf("0%s", month_num)
}

fields_to_remove <- c("includes_time_change", "month", "year")
sensor_metadata <- sensor_metadata[setdiff(
  names(sensor_metadata), fields_to_remove
)]

report_folder <- file.path(
  "facility_reports", sprintf("%s%s_reports", month_abbrev, year_int)
)
if (!(dir.exists(report_folder))) {
  dir.create(report_folder)
}

for (location in names(sensor_metadata)[1:2]) {
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
      facility_photo_dir = file.path("facility_photos", location_photo_file),
      outdoor_file_dir = file.path(
        "outdoor_data_processed",
        sprintf("%s%s", month_char, year_int),
        sprintf("%s.csv", outdoor_sensor_id)
      ),
      indoor_file_dir = file.path(
        "indoor_data_processed",
        sprintf("%s%s", month_char, year_int),
        sprintf(
          "%s_pred_%s_%s_01.csv", indoor_sensor_id, year_int, month_num
        )
      )
    ),
    clean = TRUE
  )
}

unlink("*.log")

location <- "Capilano_Library"
month <- "September"

generate_one_report <- function(
  year_int,
  month_char,
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
#   output_file = "GilliesBay_Test_Sept2025.pdf",
#   params = list(
#     year = 2025,
#     month = "September",
#     location = "Gillies Bay Public Library",
#     facility_photo_dir = "facility_photos/GilliesBay_Photo.png",
#     outdoor_file_dir = "outdoor_data_processed/September2025/2040.csv",
#     indoor_file_dir = "indoor_data_processed/September2025/2044_pred_2025_09_01.csv"
#   )
# )
