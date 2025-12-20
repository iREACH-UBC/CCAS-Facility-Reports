# Preprocess Sensor Data References

## Table of Contents

- [process_sensor_data_df](#process_sensor_data_df)
- [process_pollutant_data_df](#process_pollutant_data_df)
- [get_processed_df_from_csv](#get_processed_df_from_csv)

## process_sensor_data_df

Processes calibrated sensor data (from Git) to a form usable by report  generator. Use this processing function if your dataframe came from git  data collection pipeline. 

### Parameters

- **calibrated_dataset_df**: A dataframe of calibrated sensor data  from git. Dataframe should have no date overlaps aside from  time change. Assumes all pollutant column types are present, including AQHI,  and that all dates are in local Vancouver time. If dates are in POSIX,  assume they have UTC timestamps even though dates represent Vancouver time.

- **month_int**: Integer representing month of year.

- **year_int**: Integer representing year.

- **start_date_char**: Char representing target start date in dataset,  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in   Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char**: Char representing target end date in dataset,  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in   Nov-Mar, and PDT if dates in Apr-Oct.

### Returns

Dataframe of processed sensor data.

## process_pollutant_data_df

Processes manually calibrated sensor data to a form usable by  report generator. Use this processing function if your dataframe  did not come from git data collection pipeline. 

### Parameters

- **pollutant_df**: A dataframe of manually calibrated sensor data.  Dataframe should have no date overlaps aside from time change. Assumes AQHI  column is missing from dataset. Dates must represent UTC or local time, and  must have a UTC timestamp (even if in local time) if in POSIX format.

- **start_date_char**: Char representing target start date in dataset,  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in   Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char**: Char representing target end date in dataset,  in YYYY-MM-DD HH:MM:SS format. Represents PST time if dates in   Nov-Mar, and PDT if dates in Apr-Oct.

- **df_dates_in_utc**: TRUE if dataset dates are in UTC, FALSE if dates  are in local time. Note that timezone stamp may read UTC even if dates  are in local time (ex. if readr::read_csv is used).

- **month_int**: Integer representing month of year.

- **year_int**: Integer representing year.

### Returns

Dataframe of processed sensor data.

## get_processed_df_from_csv

Given a csv directory, generates sensor data that is ready to use in  CCAS report generator. Assumes that csv has been processed to run  in CCAS report generator if it is in the standard outdoor or indoor  processed data folder. Assumes that csv came from Github if it has  same columns as Github files, or that csv came from manual  calibrations if it contains same columns as manually calibrated data. 

### Parameters

- **csv_dir**: Directory (char) of sensor data csv.

- **start_date_char**: Char representing target start date in  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST time  if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **end_date_char**: Char representing target end date in  sensor datasets, in YYYY-MM-DD HH:MM:SS format. Represents PST time  if dates in Nov-Mar, and PDT if dates in Apr-Oct.

- **outdoor_processed_data_folder**: Name (char) of outdoor  processed data folder.

- **indoor_processed_data_folder**: Name (char) of indoor  processed data folder.

- **dates_in_utc**: TRUE if csv dates are in UTC timezone,  FALSE if in local time. Always FALSE if data is processed  (in a processed data folder). Manual data from RAMPs are  often in local time, and manual data from QAQs are often in UTC.

- **month_int**: Integer representing month.

- **year_int**: Integer representing year.

### Returns

Dataframe of processed sensor data.

