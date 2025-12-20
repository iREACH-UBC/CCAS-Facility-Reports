# Sensor Flagging Functions References

## Table of Contents

- [get_actual_num_times_per_dataset](#get_actual_num_times_per_dataset)
- [get_expected_num_times_per_dataset](#get_expected_num_times_per_dataset)
- [get_sensor_uptime](#get_sensor_uptime)
- [remove_days_with_low_uptime](#remove_days_with_low_uptime)

## get_actual_num_times_per_dataset

Counts the number of different times where non-NA pollutant  data (NO2, NO, CO, O3) is reported in a dataset. 

### Parameters

- **dataset**: Dataframe of processed sensor data. Assumes no duplicate  date entries in dataset.

### Returns

Number (int) of different times in the dataset.

## get_expected_num_times_per_dataset

Gets the expected number of different times where non-NA pollutant data  (NO2, NO, CO, O3) is reported in a dataset. Assumes data is measured in  15 minute time intervals. 

### Parameters

- **start_date_char**: Char representing target start date in dataset.  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST  time if the dataset is for a month in Nov-Mar, and PDT if the  dataset is for a month in Apr-Oct.

- **end_date_char**: Char representing target end date in dataset.  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST  time if the dataset is for a month in Nov-Mar, and PDT if the  dataset is for a month in Apr-Oct.

### Returns

Expected number (int) of different times per date.

## get_sensor_uptime

Calculates the proportion of time a sensor is operational. Assumes  sensor data is sampled every 15 minutes. Assumes at least one  expected data entry in dataset (end date > start date). 

### Parameters

- **dataset**: Dataframe of processed sensor data. Assumes no duplicate  date entries in dataset. Dataframe must not have date entries before  start date or after stop date.

- **start_date_char**: Char representing target start date in dataset.  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST  time if the dataset is for a month in Nov-Mar, and PDT if the  dataset is for a month in Apr-Oct.

- **end_date_char**: Char representing target end date in dataset.  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST  time if the dataset is for a month in Nov-Mar, and PDT if the  dataset is for a month in Apr-Oct.

### Returns

Expected number (int) of different times per date.

## remove_days_with_low_uptime

Returns the sensor data provided but with certain days' data removed  if sensor uptime over those days is less than the data proportion. 

### Parameters

- **dataset**: Dataframe of processed sensor data. Assumes no duplicate  date entries in dataset. Dataframe must not have date entries before  start date or after stop date.

- **start_date_char**: Char representing target start date in dataset.  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST  time if the dataset is for a month in Nov-Mar, and PDT if the  dataset is for a month in Apr-Oct.

- **end_date_char**: Char representing target end date in dataset.  Represents date in YYYY-MM-DD HH:MM:SS format. Dates represent PST  time if the dataset is for a month in Nov-Mar, and PDT if the

- **uptime_threshold**: Double between 0 and 1 representing sensor  uptime proportion. This value is a chosen sensor uptime threshold;  dates with uptimes below this threshold are removed from the dataset.  dataset is for a month in Apr-Oct.

### Returns

Dataframe of sensor dataset after omitting days with low uptime.

