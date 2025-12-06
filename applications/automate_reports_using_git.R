#' Generates indoor and outdoor datasets from Git, saves them to csvs,
#' and uses them to produce a CCAS facility report.
#'
#' @param start_date_char_outdoors Char representing target start date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char_outdoors Char representing target end date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param start_date_char_indoors Char representing target start date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char_indoors Char representing target end date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format.
#' @param outdoor_sensor_id Char or int of outdoor sensor ID.
#' @param indoor_sensor_id Char or int of indoor sensor ID.
#' @param location Name of facility location (char). Name
#'  must match the location name in sensor data json file.
#' @param facility_photo_directory Directory (char) where photo of facility
#'  is stored. Directory includes photo file.
#' @param month_char Full name of month (char).
#' @param year_int Integer representing year.
#' @param outdoor_csv_folder Name (char) of outdoor sensor data csv folder.
#' @param indoor_csv_folder Name (char) of indoor sensor data csv folder.
#' @param report_folder_directory Directory (char) where report is stored.
#'  Directory does not include report file.
get_report_from_git_csvs <- function(
  start_date_char_outdoors, end_date_char_outdoors,
  start_date_char_indoors, end_date_char_indoors,
  outdoor_sensor_id, indoor_sensor_id,
  location, facility_photo_directory,
  month_char, year_int, outdoor_csv_folder,
  indoor_csv_folder, report_folder_directory
) {
  month_int <- match(month_char, month.name)
  month_abbrev <- month.abb[month_int]
  location_name_compressed <- gsub("_", "", location)

  if (!(dir.exists(report_folder_directory))) {
    dir.create(report_folder_directory)
  }
  if ((month_char == "March") || (month_char == "November")) {
    timezone <- "Etc/GMT+8"
  } else {
    timezone <- "US/Pacific"
  }
  sensor_ids <- c(
    "outdoor_sensor_ID" = outdoor_sensor_id,
    "indoor_sensor_ID" = indoor_sensor_id
  )
  start_dates <- c(
    start_date_char_outdoors,
    start_date_char_indoors
  )
  end_dates <- c(
    end_date_char_outdoors,
    end_date_char_indoors
  )

  for (i in seq_along(sensor_ids)) {
    raw_urls <- file_processor$get_raw_git_urls(
      start_date = start_dates[[i]],
      stop_date = end_dates[[i]],
      sensor_id = sensor_ids[[i]]
    )
    print(sprintf("Getting data files from Git for sensor %s", sensor_ids[[i]]))
    sensor_data_df <- file_processor$get_df_from_raw_git_urls(raw_urls)

    if (!(is.null(sensor_data_df))) {
      processed_sensor_data_df <- sensor_data_processor$process_sensor_data_df(
        sensor_data_df, month_int, year_int,
        start_date_char, end_date_char
      )
      if (sensor_ids[[i]] == outdoor_sensor_id) {
        location_folder <- outdoor_csv_folder
        outdoor_data_df <- processed_sensor_data_df
      } else {
        location_folder <- indoor_csv_folder
        indoor_data_df <- processed_sensor_data_df
      }
      print(sprintf("Saving data to csv for sensor %s", sensor_ids[[i]]))
      file_processor$save_sensor_data_csv(
        month_char, year_int, location_folder,
        processed_sensor_data_df, timezone,
        sensor_ids[[i]]
      )
    } else {
      print(sprintf(paste(
        "Could not collect data for sensor %s.",
        "Git files may be unavailable for your date range."
      ), sensor_ids[[i]])
      )
    }
  }
  if (exists("outdoor_data_df") && exists("indoor_data_df")) {
    print(sprintf(
      "Generating facility report for %s", chartr("_", " ", location)
    ))
    report_generator$generate_one_report(
      year_int = year_int,
      month_char = month_char,
      start_date_char_outdoors = start_date_char_outdoors,
      start_date_char_indoors = start_date_char_indoors,
      end_date_char_outdoors = end_date_char_outdoors,
      end_date_char_indoors = end_date_char_indoors,
      facility_location_char = chartr("_", " ", location),
      facility_photo_directory = facility_photo_directory, # File inclusive
      outdoor_file_df = outdoor_data_df,
      indoor_file_df = indoor_data_df,
      output_file_name = sprintf(
        "Report_%s_%s%s.pdf", location_name_compressed, month_abbrev, year_int
      ),
      output_file_directory = report_folder_directory # File exclusive
    )
  } else {
    print(sprintf(
      "Failed to generate report for %s", chartr("_", " ", location)
    ))
  }
}


#' Generates indoor and outdoor datasets from Git, saves them to csvs,
#'  and uses them to produce CCAS facility reports. Creates reports for all
#'  locations in sensor data json that have indoor/outdoor data files for
#'  the month available on Git.
#'
#' @param month_char Full name of month (char).
#' @param year_int Integer representing year.
#' @param start_date_char Char representing target start date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format.
#' @param end_date_char Char representing target end date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format.
#' @param sensor_metadata Data (list) read from sensor json file.
#' @param overall_report_folder_name Name (char) of facility reports folder.
#' @param overall_photos_folder_name Name (char) of facility photos folder.
#' @param overall_outdoor_data_folder Name (char) of
#'  outdoor sensor data csv folder.
#' @param overall_indoor_data_folder Name (char) of
#'  indoor sensor data csv folder.
get_all_reports_from_git_csvs <- function(
  month_char, year_int, start_date_char,
  end_date_char, sensor_metadata,
  overall_report_folder_name,
  overall_photos_folder_name,
  overall_outdoor_data_folder,
  overall_indoor_data_folder
) {
  month_int <- match(month_char, month.name)
  month_abbrev <- month.abb[month_int]

  # Define and create report folder
  report_folder <- file.path(
    overall_report_folder_name, sprintf("%s%s_reports", month_abbrev, year_int)
  )

  for (location in names(sensor_metadata)) {
    location_data <- sensor_data[[location]]
    outdoor_sensor_id <- location_data[["outdoor_sensor_ID"]]
    indoor_sensor_id <- location_data[["indoor_sensor_ID"]]
    location_photo_file <- location_data[["photo_file_name"]]

    get_report_from_git_csvs(
      start_date_char_outdoors = start_date_char,
      start_date_char_indoors = start_date_char,
      end_date_char_outdoors = end_date_char,
      end_date_char_indoors = end_date_char,
      outdoor_sensor_id = outdoor_sensor_id,
      indoor_sensor_id = indoor_sensor_id,
      location = location,
      facility_photo_directory = file.path(
        overall_photos_folder_name, location_photo_file
      ),
      month_char = month_char, year_int = year_int,
      outdoor_csv_folder = overall_outdoor_data_folder,
      indoor_csv_folder = overall_indoor_data_folder,
      report_folder_directory = report_folder
    )
  }
}
