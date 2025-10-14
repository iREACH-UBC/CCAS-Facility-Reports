library(jsonlite)

sensor_metadata <- fromJSON("sensor_data.json")
includes_time_change <- sensor_data$includes_time_change
month_char <- sensor_data$month_char
year_int <- sensor_data$year

num_extra_fields <- 3
sensor_metadata <- sensor_metadata[-c((num_extra_fields - 2):num_extra_fields)]

outdoor_sensor_ids <- lapply(sensor_metadata, function(x) x$outdoor_sensor_ID)
indoor_sensor_ids <- lapply(sensor_metadata, function(x) x$indoor_sensor_ID)