# File Processing Functions References

## Table of Contents

- [get_raw_git_urls](#get_raw_git_urls)
- [get_df_from_raw_git_urls](#get_df_from_raw_git_urls)
- [get_df_from_git_files](#get_df_from_git_files)
- [get_aqhi_column](#get_aqhi_column)
- [save_sensor_data_csv](#save_sensor_data_csv)
- [separate_df_by_day](#separate_df_by_day)

## get_raw_git_urls

Gets raw urls of calibrated sensor data files from Github. 

### Parameters

- **start_date**: Start date (char, in YYYY-MM-DD format) of data date range.

- **stop_date**: End date (char, in YYYY-MM-DD format) of data date range.

- **sensor_id**: Char or int of a sensor ID.

### Returns

Raw git url (char). Returns one url or a vector of urls.

## get_df_from_raw_git_urls

Gets sensor data from raw git urls of calibrated data. Assumes empty  csvs are published to Github for any days with no data. 

### Parameters

- **raw_git_urls**: Vector or list of raw git urls (char) for one sensor.

### Returns

One dataframe with sensor data from git urls, if data available.  If sensor data unavailable, returns NULL.

## get_df_from_git_files

Gets sensor data from raw git urls of calibrated data. Assumes empty  csvs are published to Github for any days with no data. 

### Parameters

- **start_date**: Start date (char, in YYYY-MM-DD format) of data date range.

- **stop_date**: End date (char, in YYYY-MM-DD format) of data date range.

- **sensor_id**: Char or int of a sensor ID.

### Returns

One dataframe with sensor data from git urls, if data available.  If sensor data unavailable, returns NULL.

## get_aqhi_column

Gets AQHI values given sensor data. Used for sensor dataframes  missing an AQHI column. 

### Parameters

- **dataset**: A dataframe of calibrated sensor data. Must have  date, NO2, O3, and PM2.5 columns.

### Returns

Vector of AQHI values (int). Each index of the vector  corresponds to a row in the dataset.

## save_sensor_data_csv

Saves processed sensor dataframe to a csv. Csv is stored by location folder / month and year / sensor name. 

### Parameters

- **month_char**: Full month name the data is from.

- **year_int**: Year the data is from.

- **location_folder**: Outdoor or indoor data folder name.

- **processed_sensor_data_df**: Processed dataframe of sensor data.

- **timezone**: "US/Pacific" if no time change in data,  "Etc/GMT+8" otherwise.

- **sensor_id**: Character or int denoting sensor ID.

### Returns

A character of csv path.

## separate_df_by_day

Saves processed sensor dataframe to a csv. Csv is stored by location folder / month and year / sensor name. 

### Parameters

- **dataset**: A dataframe with a column named date.

- **start_date_char**: Target start date (char, in YYYY-MM-DD format)  of data date range.

- **end_date_char**: Target end date (char, in YYYY-MM-DD format)  of data date range.

- **location_folder**: Outdoor or indoor data folder name.

- **processed_sensor_data_df**: Processed dataframe of sensor data.

- **timezone**: "US/Pacific" if no time change in data,  "Etc/GMT+8" otherwise.

- **sensor_id**: Character or int denoting sensor ID.

### Returns

A list where each component contains a dataframe (from the dataset)  for a different day of the month. Dates without data contain a dataframe  with no rows.

