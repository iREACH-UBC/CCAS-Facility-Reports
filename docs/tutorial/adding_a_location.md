# Adding Sensors/Locations

## Context

Sensor metadata for the CCAS Project is stored in a
[sensor data json](../../sensor_data.json) file.
This file is used in some of the report generating applications
to match a sensor location with its outdoor sensor ID, indoor
sensor ID, and its facility photo. If a sensor was deployed
recently and you will be using the report generating scripts,
it is recommended to add this sensor to the sensor data json.

## Procedure

First, get a photo of the facility and upload it to the
[facility photos folder](../../facility_photos). There is no
naming format for the photo, but the photo type should be
readable by an R Markdown file (image formats like png and
jpg are supported, heic is not).

Next, go to the [sensor data json](../../sensor_data.json) file
and add a new json object denoted by the facility name. This
location name should be the name of the facility as you would
like to have it on the report, but with spaces replaced by
underscores. Inside this json object, add the outdoor sensor ID,
indoor sensor ID, and file name of the facility photo that you
uploaded, following the format of the other locations. Note that
sensor IDs are characters, but indoor sensor IDs can alse be
integers. Also note that you only need to add the facility file
name, and not the full directory.