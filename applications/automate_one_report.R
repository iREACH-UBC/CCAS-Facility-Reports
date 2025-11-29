# TODO: change source path after moving files around
source("applications/generate_report.R")
source("applications/preprocess_sensor_data.R")
source("libraries/helper_functions.R")

# TODO: delete non-functions after testing

# Get metadata used in processing
# Assumes same start/end dates for each sensor
# Start user adjustable parameters
json_file_dir <- "sensor_data.json"
month_char <- "October"
month_int <- match(month_char, month.name) # Do not change
year_int <- 2025
month_dates <- get_month_start_end_dates(month_int, year_int)
start_date_char <- month_dates[["month_start_date"]]
end_date_char <- month_dates[["month_end_date"]]
# End user adjustable parameters

sensor_data <- jsonlite::fromJSON(json_file_dir)
includes_time_change <- data_includes_time_change(
  month_int, start_date_char, end_date_char, year_int
)

# location must match chosen location from sensor_data json
get_report_from_git_csvs <- function(
  start_date_char, end_date_char, outdoor_sensor_id,
  indoor_sensor_id, location, facility_photo_directory,
  month_char, year_int, includes_time_change,
  outdoor_csv_folder, indoor_csv_folder, report_folder_directory
) {
  month_int <- match(month_char, month.name)
  month_abbrev <- month.abb[month_int]
  location_name_compressed <- gsub("_", "", location)

  if (!(dir.exists(report_folder_directory))) {
    dir.create(report_folder_directory)
  }
  if (includes_time_change) {
    timezone <- "Etc/GMT+8"
  } else {
    timezone <- "US/Pacific"
  }
  sensor_ids <- c(
    "outdoor_sensor_ID" = outdoor_sensor_id,
    "indoor_sensor_ID" = indoor_sensor_id
  )

  for (id in sensor_ids) {
    raw_urls <- get_file_urls(
      start_date = start_date_char,
      stop_date = end_date_char,
      sensor_id = id
    )
    print(sprintf("Getting data files from Git for sensor %s", id))
    sensor_data_df <- get_df_from_raw_git_urls(raw_urls) # Dates in POSIXct

    if (!(is.null(sensor_data_df))) {
      processed_sensor_data_df <- process_sensor_data_df(
        includes_time_change, sensor_data_df, month_int, year_int,
        start_date_char, end_date_char
      )
      if (id == outdoor_sensor_id) {
        location_folder <- outdoor_csv_folder
        outdoor_data_df <- processed_sensor_data_df
      } else {
        location_folder <- indoor_csv_folder
        indoor_data_df <- processed_sensor_data_df
      }
      print(sprintf("Saving data to csv for sensor %s", id))
      save_sensor_data_csv(
        month_char, year_int, location_folder,
        processed_sensor_data_df, timezone,
        id
      )
    } else {
      print(sprintf(paste(
        "Could not collect data for sensor %s.",
        "Git files may be unavailable for your date range."
      ), id)
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
      start_date_char = start_date_char,
      end_date_char = end_date_char,
      includes_time_change = includes_time_change,
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

get_all_reports_from_git_csvs <- function(
  month_char, year_int, includes_time_change,
  start_date_char, end_date_char, sensor_metadata,
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
      start_date_char = start_date_char,
      end_date_char = end_date_char,
      outdoor_sensor_id = outdoor_sensor_id,
      indoor_sensor_id = indoor_sensor_id,
      location = location,
      facility_photo_directory = file.path(
        overall_photos_folder_name, location_photo_file
      ),
      month_char = month_char, year_int = year_int,
      includes_time_change = includes_time_change,
      outdoor_csv_folder = overall_outdoor_data_folder,
      indoor_csv_folder = overall_indoor_data_folder,
      report_folder_directory = report_folder
    )
  }
}

# Use when you cannot get data for both indoor and outdoor from Git
# Csv from git means csv came from git data collection pipeline
# TODO: make into two functions instead!!
get_report_from_csvs <- function(
  year_int, month_char, start_date_char,
  end_date_char, includes_time_change,
  location_char, outdoor_csv_dir,
  indoor_csv_dir, outdoor_csv_from_git,
  indoor_csv_from_git, outdoor_dates_in_utc,
  indoor_dates_in_utc
) {
  csv_dirs <- c(outdoor_csv_dir, indoor_csv_dir)
  csvs_from_git <- c(outdoor_csv_from_git, indoor_csv_from_git)
  dates_in_utc <- c(outdoor_dates_in_utc, indoor_dates_in_utc)
  processed_dfs <- c(NULL, NULL)

  for (i in seq_along(csv_dirs)) {
    sensor_data <- readr::read_csv(csv_dirs[[i]])

    if (csvs_from_git[[i]]) {
      processed_dfs[[i]] <- process_sensor_data_df(
        #TODO
      )
    } else {
      processed_dfs[[i]] <- process_pollutant_data_df(
        #TODO
        pollutant_df = sensor_data[[i]],
        start_date_char = start_date_char,
        end_date_char = end_date_char,
        csv_dates_in_utc = dates_in_utc[[i]],
        data_includes_time_change = includes_time_change
      )
    }
  }
  process_pollutant_data_df(
    pollutant_df, start_date_char, end_date_char, csv_dates_in_utc,
    data_includes_time_change, month_int, year_int
  )

  generate_one_report(
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
  )
}

# Testing functions

# get_report_from_git_csvs(
#   start_date_char = start_date_char,
#   end_date_char = end_date_char,
#   outdoor_sensor_id = "2032",
#   indoor_sensor_id = "2049",
#   location = "Squamish_Nation_Totem_Hall",
#   facility_photo_directory = "facility_photos/SquamishNationTotemHall_Photo.png",
#   month_char = month_char, year_int = year_int,
#   includes_time_change = includes_time_change,
#   outdoor_csv_folder = "test_pipeline_outdoor2",
#   indoor_csv_folder = "test_pipeline_indoor2",
#   report_folder_directory = "test_pipeline_reports2"
# )

get_all_reports_from_git_csvs(
  month_char = month_char,
  year_int = year_int,
  includes_time_change = includes_time_change,
  start_date_char = start_date_char,
  end_date_char = end_date_char,
  sensor_metadata = sensor_data,
  overall_report_folder_name = "test_pipeline_reports2",
  overall_photos_folder_name = "facility_photos",
  overall_outdoor_data_folder = "test_pipeline_outdoor2",
  overall_indoor_data_folder = "test_pipeline_indoor2"
)