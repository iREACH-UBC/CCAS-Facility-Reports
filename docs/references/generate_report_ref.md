# Generate Report References

## Table of Contents

- [generate_one_report](#generate_one_report)

## generate_one_report

Generates a CCAS facility report from outdoor and indoor datasets. 

### Parameters

- **year_int**: Integer representing year.

- **month_char**: Full name of month (char).

- **start_date_char_outdoors**: Char representing target start date in  outdoor dataset, in YYYY-MM-DD HH:MM:SS format.

- **end_date_char_outdoors**: Char representing target end date in  outdoor dataset, in YYYY-MM-DD HH:MM:SS format.

- **start_date_char_indoors**: Char representing target start date in  indoor dataset, in YYYY-MM-DD HH:MM:SS format.

- **end_date_char_indoors**: Char representing target end date in  indoor dataset, in YYYY-MM-DD HH:MM:SS format.

- **facility_location_char**: Name of facility location (char). Name  must match the location name in sensor data json file.

- **facility_photo_directory**: Directory (char) where photo of facility  is stored. Directory includes photo file.

- **outdoor_file_df**: Processed outdoor data dataframe.

- **indoor_file_df**: Processed indoor data dataframe.

- **output_file_name**: Name of report (char).

- **output_file_directory**: Directory (char) where report is stored.  Directory does not include report file.

