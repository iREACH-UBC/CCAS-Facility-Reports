# Generating Reports With Existing Applications

Four scripts are available for four different use cases:
generating one report from Github files, one report from
csvs, all reports from Github files, and all reports from
manually calibrated csvs. These scripts are calls to functions
found in this [report automation file](../../applications/report_automation.R), with user adjustable parameters
denoted clearly. Note that all report generating scripts also
save csvs of processed sensor data to processed data folders,
and save reports to a [facility reports](../../facility_reports)
folder.


## Generating All Reports From Github Data

To generate reports for all locations in your [sensor data
json](../../sensor_data.json) using Github files, use [this
script](../../applications/get_reports_from_git.R).
Documentation for the `get_all_reports_from_git_csvs`
function can be found
[here](../references/report_automation_ref.md#get_all_reports_from_git_csvs).

Note that this function
will generate reports for all locations with data available on
Github (data must be available for both outdoor and indoor
sensors within the specified date range). The script will not
stop if the data for a location is unavailable, but it will not
generate a report for that location. Another note for this
function is that it assumes the same start and end date for
each location's sensor data.

If the Github data is trustworthy, it is recommended to use this
script to generate reports, and manage locations with missing
data or different date ranges individually.
Use the [`get_one_report_from_git`](../../applications/get_one_report_from_git.R) script if you want to
use Github data but want to use a different date range for a
location, or the [`get_one_report_from_csvs`](../../applications/get_one_report_from_csvs.R) script if data is unavailable on
Github for a location.

## Generating All Reports From Manually Calibrated CSVs

To generate reports for all locations in your [sensor data
json](../../sensor_data.json) using manually calibrated csvs,
use [this script](../../applications/get_reports_from_csvs.R).
Documentation for the `get_reports_from_manual_csvs`
function can be found [here](../references/report_automation_ref.md#get_reports_from_manual_csvs).

Note that this method requires the user to upload a folder of
unprocessed sensor data files to the workspace, and state
the folder directory as a parameter. This script also assumes tha
same date range for all sensors.

Use this script when you want reports for all locations, and
manually calibrated data is more reliable than Github. To
specify a different date range for a sensor in a certain
location, do this individually through the
[`get_one_report_from_csvs`](../../applications/get_one_report_from_csvs.R) script.

## Generating One Report Using Github Files

To generate a report for one location using Github files, use
[this script](../../applications/get_one_report_from_git.R).
Documentation for the `get_one_report_from_git_csvs`
function can be found
[here](../references/report_automation_ref.md#get_report_from_git_csvs).

## Generating One Report Using CSVs

To generate a report for one location using CSVs, use
[this script](../../applications/get_one_report_from_csvs.R).
Documentation for the `get_one_report_from_csvs`
function can be found
[here](../references/report_automation_ref.md#get_report_from_csvs).

Note that the csvs in this function may be manually calibrated
csvs, unprocessed csvs from Github, or processed csvs. The
function automatically detects the csv types and processes them
accordingly. Outdoor and indoor csvs may have different formats.