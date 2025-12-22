# Report Automation References

## Table of Contents

- [get_report_from_git_csvs](#get_report_from_git_csvs)
- [get_all_reports_from_git_csvs](#get_all_reports_from_git_csvs)
- [get_report_from_csvs](#get_report_from_csvs)
- [get_reports_from_manual_csvs](#get_reports_from_manual_csvs)

## get_report_from_git_csvs

Generates indoor and outdoor datasets from Git, saves them to csvs, and uses them to produce a CCAS facility report. 

### Parameters

- **start_date_char_outdoors**: Char representing target start date in  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char_outdoors**: Char representing target end date in  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **start_date_char_indoors**: Char representing target start date in  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char_indoors**: Char representing target end date in  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **outdoor_sensor_id**: Char or int of outdoor sensor ID.

- **indoor_sensor_id**: Char or int of indoor sensor ID.

- **location**: Name of facility location (char). Name  must match the location name in sensor data json file.

- **facility_photo_directory**: Directory (char) where photo of facility  is stored. Directory includes photo file.

- **month_char**: Full name of month (char).

- **year_int**: Integer representing year.

- **outdoor_csv_folder**: Name (char) of outdoor sensor data csv folder.

- **indoor_csv_folder**: Name (char) of indoor sensor data csv folder.

- **report_folder_directory**: Directory (char) where report is stored.  Directory does not include report file.

## get_all_reports_from_git_csvs

Generates indoor and outdoor datasets from Git, saves them to csvs,  and uses them to produce CCAS facility reports. Creates reports for all  locations in sensor data json that have indoor/outdoor data files for  the month available on Git. Assumes same date range for all sensor datasets. 

### Parameters

- **month_char**: Full name of month (char).

- **year_int**: Integer representing year.

- **start_date_char**: Char representing target start date in  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char**: Char representing target end date in  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **sensor_metadata**: Data (list) read from sensor json file.

- **overall_report_folder_name**: Name (char) of facility reports folder.  Does not include sub-folders.

- **overall_photos_folder_name**: Name (char) of facility photos folder.  Does not include sub-folders.

- **overall_outdoor_data_folder**: Name (char) of  outdoor sensor data csv folder. Does not include sub-folders.

- **overall_indoor_data_folder**: Name (char) of  indoor sensor data csv folder. Does not include sub-folders.

## get_report_from_csvs

Reads indoor and outdoor data from csvs, processes them if needed,  and saves them to csvs with standardized name conventions and  file locations. Generates CCAS facility report with this data. 

### Parameters

- **outdoor_csv_dir**: Directory (char) of outdoor data csv.

- **indoor_csv_dir**: Directory (char) of indoor data csv.

- **outdoor_processed_data_folder**: Name (char) of outdoor  processed data folder

- **indoor_processed_data_folder**: Name (char) of indoor  processed data folder

- **report_folder**: Name (char) of overall folder where  reports are stored. Does not include sub-folders.

- **start_date_char_outdoors**: Char representing target start date in  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char_outdoors**: Char representing target end date in  outdoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **start_date_char_indoors**: Char representing target start date in  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char_indoors**: Char representing target end date in  indoor dataset, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **outdoor_dates_in_utc**: TRUE if outdoor csv dates are in UTC timezone,  FALSE if in local time. Always FALSE if data is processed  (in a processed data folder). Manual data from RAMPs are  often in local time, and manual data from QAQs are often in UTC.  Git data is never in UTC.

- **indoor_dates_in_utc**: TRUE if indoor csv dates are in UTC timezone,  FALSE if in local time. Always FALSE if data is processed  (in a processed data folder). Manual data from RAMPs are  often in local time, and manual data from QAQs are often in UTC.  Git data is never in UTC.

- **month_char**: Full name of month (char).

- **year_int**: Integer representing year.

- **outdoor_sensor_id**: Char or int of outdoor sensor ID.

- **indoor_sensor_id**: Char or int of indoor sensor ID.

- **location**: Name of facility location (char). Name  must match the location name in sensor data json file.

- **facility_photo_dir**: Directory (char) where photo of facility  is stored. Directory includes photo file.

## get_reports_from_manual_csvs

Reads indoor and outdoor data from unprocessed csvs, processes  them, and saves them to csvs with standardized name conventions  and file locations. Generates CCAS facility report with this data. Assumes same date range for all sensor datasets. Assumes unprocessed  sensor file names contain sensor ID followed by _pred, ex. 2029_pred.  Assumes QAQ data files have MOD in their file name, and all other  data files come from RAMPs. 

### Parameters

- **unprocessed_data_folder_dir**: Directory (char) of folder  of manually calibrated sensor data csvs.

- **sensor_metadata**: Data (list) read from sensor json file.

- **start_date_char**: Char representing target start date in  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char**: Char representing target end date in  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST  time if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **ramps_in_utc**: TRUE if RAMP datasets are in UTC timezone,  FALSE if in local time. Set to FALSE if you are using processed  data (from processed data folder)

- **qaqs_in_utc**: TRUE if QAQ datasets are in UTC timezone,  FALSE if in local time. Set to FALSE if you are using processed  data (from processed data folder)

- **outdoor_processed_data_folder**: Name (char) of outdoor  processed data folder

- **indoor_processed_data_folder**: Name (char) of indoor  processed data folder

- **report_folder**: Name (char) of overall folder where  reports are stored. Does not include sub-folders.

- **month_char**: Full name of month (char).

- **year_int**: Integer representing year.

- **overall_photos_folder_name**: Name (char) of facility photos folder.  Does not include sub-folders.

