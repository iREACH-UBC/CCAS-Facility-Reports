# Time Processing Functions References

## Table of Contents

- [get_month_start_end_dates](#get_month_start_end_dates)
- [shift_timezones_at_time_change](#shift_timezones_at_time_change)
- [get_time_change_date](#get_time_change_date)
- [set_timezone_from_month](#set_timezone_from_month)
- [remove_out_of_range_data](#remove_out_of_range_data)

## get_month_start_end_dates

Gets the start and end dates of a month in YYYY-MM-DD HH:MM:SS format. Time portion is 00:00:00 for start date, 23:45:00 for end date. 

### Parameters

- **month_int**: Integer representing month, ex. 2 for February.

- **year_int**: Year the data is from (int or char).

### Returns

List composed of start and end dates (char).  Use "month_start_date" or "month_end_date" to access start/end date

### Examples

```r
@examples
get_month_start_end_dates(12, 2025)
```

## shift_timezones_at_time_change

Sets the timezone of all dates to the final timezone 

### Parameters

- **dates**: Dates in POSIX. Dates before time change have timezone_b4  timezone and dates after are in timezone_after, but the time zone  identifiers may be different.

- **index_b4_change**: Index (int) of last date before time change.

- **timezone_b4**: Timezone identifier (char) for times before time change.

- **timezone_after**: Timezone identifier (char) for times after time change.

- **final_timezone**: Timezone identifier (char) for final timezone.

### Returns

Dates (char) with their timezone set to final_timezone.

## get_time_change_date

Gets time change date for given month and year. 

### Parameters

- **month_int**: Integer representing month of time change.  3 for March or 11 for November are the only accepted inputs.

- **year_int**: Year of time change date.

### Returns

Time change date (char) in YYYY-MM-DD HH:MM:SS format.  If time falls back, the hour for this date is the time immediately  after falling back. If time jumps ahead, the hour for this date is the  time immediately after jumping ahead.

## set_timezone_from_month

Sets timezone of dates to PST if data in a time change month.  Sets timezone to either PST or PDT otherwise. 

### Parameters

- **dates**: Dates in POSIX format. If characters are read to  POSIX times here, they must have YYYY-MM-DD HH:MM:SS format.  Dates must have UTC timestamp even if they are in local time.

- **month_int**: Integer representing month.

- **year_int**: Integer representing year.

- **dates_in_utc**: Boolean representing if the dates are in UTC.  Assumes dates are in local Vancouver time if false. Note that  dates may be in local time even if POSIX timestamp is in UTC.

### Returns

Dates (POSIX) in PST or PDT.

## remove_out_of_range_data

Removes components of datset outside of start/end dates. 

### Parameters

- **dataset_df**: Dataframe of sensor data. Must have a column of  dates with the column named date

- **start_date_char**: Start date (char) in YYYY-MM-DD HH:MM:SS format.  Time portion can be omitted only if start date is at midnight.

- **end_date_char**: End date (char) in YYYY-MM-DD HH:MM:SS format.  Time portion can be omitted only if end date is at midnight.

### Returns

Dataset with out-of-range rows omitted.

