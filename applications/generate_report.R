source("libraries/helper_functions.R")

# If report generated from csvs, read csvs to get them to df
# Force tz to PST if time change, local time otherwise (for df from csv)
generate_one_report <- function(
  year_int,
  month_char,
  start_date_char_outdoors,
  start_date_char_indoors,
  end_date_char_outdoors,
  end_date_char_indoors,
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
      start_date_char_outdoors = start_date_char_outdoors,
      start_date_char_indoors = start_date_char_indoors,
      end_date_char_outdoors = end_date_char_outdoors,
      end_date_char_indoors = end_date_char_indoors,
      facility_photo_dir = facility_photo_directory,
      outdoor_dataset = outdoor_file_df,
      indoor_dataset = indoor_file_df
    ),
    clean = TRUE
  )
  unlink("*.log") # Delete log files
}
