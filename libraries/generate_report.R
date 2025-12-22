#' Generates a CCAS facility report from outdoor and indoor datasets.
#'
#' @param year_int Integer representing year.
#' @param month_char Full name of month (char).
#' @param start_date_char_outdoors Char representing target start date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char_outdoors Char representing target end date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param start_date_char_indoors Char representing target start date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char_indoors Char representing target end date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param facility_location_char Name of facility location (char). Name
#'  must match the location name in sensor data json file.
#' @param facility_photo_directory Directory (char) where photo of facility
#'  is stored. Directory includes photo file.
#' @param outdoor_file_df Processed outdoor data dataframe.
#' @param indoor_file_df Processed indoor data dataframe.
#' @param output_file_name Name of report (char).
#' @param output_file_directory Directory (char) where report is stored.
#'  Directory does not include report file.
generate_one_report <- function(
  year_int,
  month_char,
  start_date_char_outdoors,
  start_date_char_indoors,
  end_date_char_outdoors,
  end_date_char_indoors,
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
