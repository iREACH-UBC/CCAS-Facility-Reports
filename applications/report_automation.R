source("libraries/preprocess_sensor_data.R")
source("libraries/file_processing_functions.R")
source("libraries/generate_report.R")

#' Generates indoor and outdoor datasets from Git, saves them to csvs,
#' and uses them to produce a CCAS facility report.
#'
#' @param start_date_char_outdoors Char representing target start date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char_outdoors Char representing target end date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param start_date_char_indoors Char representing target start date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char_indoors Char representing target end date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
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
    # Modify end dates if there is a time change, ensures no time missed
    stop_date <- substring(end_dates[[i]], 1, 10) # Do not include time
    if (month_int == 3 || month_int == 11) {
      last_date <- format(
        lubridate::ymd_hms(end_dates[[i]]) + lubridate::hours(1),
        "%Y-%m-%d %H:%M:%S"
      )
      stop_date <- substring(last_date, 1, 10)
    }

    raw_urls <- get_raw_git_urls(
      start_date = substring(start_dates[[i]], 1, 10), # Do not include time
      stop_date = stop_date,
      sensor_id = sensor_ids[[i]]
    )
    print(sprintf("Getting data files from Git for sensor %s", sensor_ids[[i]]))
    sensor_data_df <- get_df_from_raw_git_urls(raw_urls)

    if (!(is.null(sensor_data_df))) {
      processed_sensor_data_df <- process_sensor_data_df(
        sensor_data_df, month_int, year_int,
        start_dates[[i]], end_dates[[i]]
      )
      if (sensor_ids[[i]] == outdoor_sensor_id) {
        location_folder <- outdoor_csv_folder
        outdoor_data_df <- processed_sensor_data_df
      } else {
        location_folder <- indoor_csv_folder
        indoor_data_df <- processed_sensor_data_df
      }
      print(sprintf("Saving data to csv for sensor %s", sensor_ids[[i]]))
      save_sensor_data_csv(
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
    generate_one_report(
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
#'  the month available on Git. Assumes same date range for all sensor datasets.
#'
#' @param month_char Full name of month (char).
#' @param year_int Integer representing year.
#' @param start_date_char Char representing target start date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char Char representing target end date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param sensor_metadata Data (list) read from sensor json file.
#' @param overall_report_folder_name Name (char) of facility reports folder.
#'  Does not include sub-folders.
#' @param overall_photos_folder_name Name (char) of facility photos folder.
#'  Does not include sub-folders.
#' @param overall_outdoor_data_folder Name (char) of
#'  outdoor sensor data csv folder. Does not include sub-folders.
#' @param overall_indoor_data_folder Name (char) of
#'  indoor sensor data csv folder. Does not include sub-folders.
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
    location_data <- sensor_metadata[[location]]
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


#' Reads indoor and outdoor data from csvs, processes them if needed,
#'  and saves them to csvs with standardized name conventions and
#'  file locations. Generates CCAS facility report with this data.
#'
#' @param outdoor_csv_dir Directory (char) of outdoor data csv.
#' @param indoor_csv_dir Directory (char) of indoor data csv.
#' @param outdoor_processed_data_folder Name (char) of outdoor
#'  processed data folder
#' @param indoor_processed_data_folder Name (char) of indoor
#'  processed data folder
#' @param report_folder Name (char) of overall folder where
#'  reports are stored. Does not include sub-folders.
#' @param start_date_char_outdoors Char representing target start date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char_outdoors Char representing target end date in
#'  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param start_date_char_indoors Char representing target start date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char_indoors Char representing target end date in
#'  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param outdoor_dates_in_utc TRUE if outdoor csv dates are in UTC timezone,
#'  FALSE if in local time. Always FALSE if data is processed
#'  (in a processed data folder). Manual data from RAMPs are
#'  often in local time, and manual data from QAQs are often in UTC.
#'  Git data is never in UTC.
#' @param indoor_dates_in_utc TRUE if indoor csv dates are in UTC timezone,
#'  FALSE if in local time. Always FALSE if data is processed
#'  (in a processed data folder). Manual data from RAMPs are
#'  often in local time, and manual data from QAQs are often in UTC.
#'  Git data is never in UTC.
#' @param month_char Full name of month (char).
#' @param year_int Integer representing year.
#' @param outdoor_sensor_id Char or int of outdoor sensor ID.
#' @param indoor_sensor_id Char or int of indoor sensor ID.
#' @param location Name of facility location (char). Name
#'  must match the location name in sensor data json file.
#' @param facility_photo_dir Directory (char) where photo of facility
#'  is stored. Directory includes photo file.
get_report_from_csvs <- function(
  outdoor_csv_dir,
  indoor_csv_dir,
  outdoor_processed_data_folder,
  indoor_processed_data_folder,
  report_folder, # Overall folder
  start_date_char_outdoors,
  end_date_char_outdoors,
  start_date_char_indoors,
  end_date_char_indoors,
  outdoor_dates_in_utc,
  indoor_dates_in_utc,
  month_char,
  year_int,
  outdoor_sensor_id,
  indoor_sensor_id,
  location,
  facility_photo_dir
) {
  month_int <- match(month_char, month.name)
  month_abbrev <- month.abb[month_int]

  # Read data from csvs, process data if needed
  print(sprintf(
    "Reading data for sensor %s, processing data if needed",
    outdoor_sensor_id
  ))
  processed_outdoor_df <- get_processed_df_from_csv(
    csv_dir = outdoor_csv_dir,
    start_date_char = start_date_char_outdoors,
    end_date_char = end_date_char_outdoors,
    outdoor_processed_data_folder = outdoor_processed_data_folder,
    indoor_processed_data_folder = indoor_processed_data_folder,
    dates_in_utc = outdoor_dates_in_utc,
    month_int = month_int,
    year_int = year_int
  )
  print(sprintf(
    "Reading data for sensor %s, processing data if needed",
    indoor_sensor_id
  ))
  processed_indoor_df <- get_processed_df_from_csv(
    csv_dir = indoor_csv_dir,
    start_date_char = start_date_char_indoors,
    end_date_char = end_date_char_indoors,
    outdoor_processed_data_folder = outdoor_processed_data_folder,
    indoor_processed_data_folder = indoor_processed_data_folder,
    dates_in_utc = indoor_dates_in_utc,
    month_int = month_int,
    year_int = year_int
  )

  # Save outdoor and indoor data to csvs with standardized name conventions,
  #  if they do not already exist
  if ((length(grep(outdoor_processed_data_folder, outdoor_csv_dir)) == 0)) {
    print(sprintf(
      "Saving sensor %s data to a csv.", outdoor_sensor_id
    ))
    save_sensor_data_csv(
      month_char = month_char,
      year_int = year_int,
      location_folder = outdoor_processed_data_folder,
      processed_sensor_data_df = processed_outdoor_df,
      timezone = lubridate::tz(processed_outdoor_df$date),
      sensor_id = outdoor_sensor_id
    )
  }
  if ((length(grep(indoor_processed_data_folder, indoor_csv_dir)) == 0)) {
    print(sprintf(
      "Saving sensor %s data to a csv.", indoor_sensor_id
    ))
    save_sensor_data_csv(
      month_char = month_char,
      year_int = year_int,
      location_folder = indoor_processed_data_folder,
      processed_sensor_data_df = processed_indoor_df,
      timezone = lubridate::tz(processed_indoor_df$date),
      sensor_id = indoor_sensor_id
    )
  }

  # Generate report
  print(sprintf(
    "Generating report for %s.", chartr("_", " ", location)
  ))
  generate_one_report(
    year_int = year_int,
    month_char = month_char,
    start_date_char_outdoors = start_date_char_outdoors,
    start_date_char_indoors = start_date_char_indoors,
    end_date_char_outdoors = end_date_char_outdoors,
    end_date_char_indoors = end_date_char_indoors,
    facility_location_char = chartr("_", " ", location),
    facility_photo_directory = facility_photo_dir, # File inclusive
    outdoor_file_df = processed_outdoor_df,
    indoor_file_df = processed_indoor_df,
    output_file_name = sprintf(
      "Report_%s_%s%s.pdf", gsub("_", "", location), month_abbrev, year_int
    ),
    output_file_directory = file.path(
      report_folder, sprintf("%s%s_reports", month_abbrev, year_int)
    )
  )
}


#' Reads indoor and outdoor data from unprocessed csvs, processes
#'  them, and saves them to csvs with standardized name conventions
#'  and file locations. Generates CCAS facility report with this data.
#' Assumes same date range for all sensor datasets. Assumes unprocessed
#'  sensor file names contain sensor ID followed by _pred, ex. 2029_pred.
#'  Assumes QAQ data files have MOD in their file name, and all other
#'  data files come from RAMPs.
#'
#' @param unprocessed_data_folder_dir Directory (char) of folder
#'  of manually calibrated sensor data csvs.
#' @param sensor_metadata Data (list) read from sensor json file.
#' @param start_date_char Char representing target start date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param end_date_char Char representing target end date in
#'  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST
#'  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.
#' @param ramps_in_utc TRUE if RAMP datasets are in UTC timezone,
#'  FALSE if in local time. Set to FALSE if you are using processed
#'  data (from processed data folder)
#' @param qaqs_in_utc TRUE if QAQ datasets are in UTC timezone,
#'  FALSE if in local time. Set to FALSE if you are using processed
#'  data (from processed data folder)
#' @param outdoor_processed_data_folder Name (char) of outdoor
#'  processed data folder
#' @param indoor_processed_data_folder Name (char) of indoor
#'  processed data folder
#' @param report_folder Name (char) of overall folder where
#'  reports are stored. Does not include sub-folders.
#' @param month_char Full name of month (char).
#' @param year_int Integer representing year.
#' @param overall_photos_folder_name Name (char) of facility photos folder.
#'  Does not include sub-folders.
get_reports_from_manual_csvs <- function(
  unprocessed_data_folder_dir,
  sensor_metadata,
  start_date_char,
  end_date_char,
  ramps_in_utc,
  qaqs_in_utc,
  outdoor_processed_data_folder,
  indoor_processed_data_folder,
  report_folder,
  month_char,
  year_int,
  overall_photos_folder_name
) {
  month_int <- match(month_char, month.name)
  
  # Gets list of file directories from unprocessed data folder
  sensor_files <- list.files(
    path = unprocessed_data_folder_dir,
    recursive = TRUE,
    full.names = TRUE
  )
  # Get report for each location in dataset
  for (location in names(sensor_metadata)) {
    location_data <- sensor_metadata[[location]]
    outdoor_sensor_id <- location_data[["outdoor_sensor_ID"]]
    indoor_sensor_id <- location_data[["indoor_sensor_ID"]]
    location_photo_file <- location_data[["photo_file_name"]]

    # Gets outdoor and indoor data files from folder
    outdoor_csv_dir <- sensor_files[grepl(sprintf(
      "%s_%04d_%02d", outdoor_sensor_id, year_int, month_int
    ), sensor_files)]
    indoor_csv_dir <- sensor_files[grepl(sprintf(
      "%s_%04d_%02d", indoor_sensor_id, year_int, month_int
    ), sensor_files)]
    
    

    # Check if data exists
    if (length(outdoor_csv_dir) != 0 && length(indoor_csv_dir) != 0) {
      # Get timezone of data
      if (grepl("MOD", outdoor_csv_dir)) {
        outdoor_dates_in_utc <- qaqs_in_utc
      } else {
        outdoor_dates_in_utc <- ramps_in_utc
      }
      if (grepl("MOD", indoor_csv_dir)) {
        indoor_dates_in_utc <- qaqs_in_utc
      } else {
        indoor_dates_in_utc <- ramps_in_utc
      }

      # Generate report
      get_report_from_csvs(
        outdoor_csv_dir = outdoor_csv_dir,
        indoor_csv_dir = indoor_csv_dir,
        outdoor_processed_data_folder = outdoor_processed_data_folder,
        indoor_processed_data_folder = indoor_processed_data_folder,
        report_folder = report_folder,
        start_date_char_outdoors = start_date_char,
        end_date_char_outdoors = end_date_char,
        start_date_char_indoors = start_date_char,
        end_date_char_indoors = end_date_char,
        outdoor_dates_in_utc = outdoor_dates_in_utc,
        indoor_dates_in_utc = indoor_dates_in_utc,
        month_char = month_char,
        year_int = year_int,
        outdoor_sensor_id = outdoor_sensor_id,
        indoor_sensor_id = indoor_sensor_id,
        location = location,
        facility_photo_dir = file.path(
          overall_photos_folder_name, location_photo_file
        )
      )
    } else {
      print(sprintf(paste(
        "Data unavailable for one or both sensors at %s.",
        "Could not generate report for this location."
        #print(outdoor_csv_dir),
        #print(indoor_csv_dir),
        
        #print(length(outdoor_csv_dir)),
        #print(length(indoor_csv_dir))
      ), gsub("_", " ", location))
      )
    }
  }
}
