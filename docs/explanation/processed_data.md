# Processed Data

## Context

Processed data in the context of this repository is calibrated
sensor data in a format compatible with the report generator.
The data obtained is already calibrated, so the processing
functions in this repository are used to format the data
appropriately. This involves ensuring all necessary columns
are present, renaming columns, setting the data to consistent
timezones, and removing data outside of the desired time range.

Processed data is stored in Pacific Standard Time for the months
of November to March, and Pacific Daylight Time for the months
of April to October.

This repository contains two folders for saved processed data:
[outdoor_data_processed](../../outdoor_data_processed) and
[indoor_data_processed](../../indoor_data_processed). All
files in these folders are fully processed and ready to be used
by the CCAS report generator.

## Processing Data

Processing functions differ depending on the input data format
(ex. data is from Github or data is manually calibrated). For
more comments on data format, see this
[explanation](../explanation/sensor_data.md).

All processing functions can be found in [this folder](../../libraries/preprocess_sensor_data.R).
See [this file](../references/preprocess_sensor_data_ref.md) for
documentation on the file processing functions.

If you have a dataframe of Github sensor data, use the
`process_sensor_data_df` function. If you have a dataframe of
manually calibrated data, use the `process_pollutant_data_df`
function. Note that these functions assume that dataframe inputs
came from reading csvs (using `read.csv`, which leaves dates as
characters, or `readr::read_csv`, which sets dates to POSIX with
UTC timestamps). Since csvs do not store date timezones, the
timezone of the input dataset must be conveyed manually through
the `df_dates_in_utc` or `dates_in_utc` argument.

Lastly, if you have a csv of sensor data, use the
`get_processed_df_from_csv` function. Note that the input csv
may be from Github, from a manual calibration, or from
already-processed sensor data.

## Saving Processed Data

It is recommended to always save **monthly** data to csvs after
processing. This ensures that users can look back on past data
and quickly regenerate reports if needed. To save processed data
to a standard processed data folder (`outdoor_data_processed` or
`indoor_data_processed`), use the `save_sensor_data_csv`
function found in [this file](../../libraries/file_processing_functions.R). Documentation for this function can be found [here](../references/file_processing_functions_ref.md).
