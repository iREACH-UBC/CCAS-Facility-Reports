# Sensor Data

## Context

Calibrated sensor data is stored on Github, in the
[CCAS_Dashboard](https://github.com/iREACH-UBC/CCAS_Dashboard/tree/main/calibrated_data) repository. However, in cases where
this data is missing or unreliable, sensor data can also be
calibrated and generated manually. Both sources contain the same
data, but the data are presented differently.

## Github Data

Calibrated data on Github is stored by sensor over 1-3 days. Note that
there is some overlap in data between each consecutive file.
Also, note that the date names on the csvs may not be fully
accurate. For example, there may not be data present for the
first date in the file name (but the last date's data is
always present in the file if the sensor is online).

The data on Github is stored in local Vancouver time. This data
includes dates, pollutant levels, AQHI, and pollutant
contributions to AQHI. This format is consistent for both indoor
and outdoor data, and for Sensit RAMP and QuantAQ Modulair
sensors.

To obtain data from Github, use the `get_df_from_git_files`
function in the [file processing functions](../../libraries/file_processing_functions.R) folder.
See [this reference](../references/file_processing_functions_ref.md#get_df_from_git_files) for function documentation.

## Manually Calibrated Data

Manually calibrated data in csv format can be obtained by bothering Hugo.
Unlike the Github data, this data contains only dates and
pollutant levels. Therefore, AQHI columns need to be added
manually. The manually calibrated data may be in local time
or UTC. As of December 20th 2025, RAMP files (which have
numerical sensor IDs) are typically in local Vancouver time,
while QAQ files (which have sensor IDs with a MOD prefix)
are typically in UTC.

```
Tip:
When using manually calibrated data, include at least three extra hours at the start of the dataset and three extra hours at the end. Do this to ensure you have sufficient data for your AQHI calculation (helps to avoid NA values at the start or end of the dataset).
```
