# Data Io References

## Table of Contents

- [sensor_data_is_from_git](#sensor_data_is_from_git)
- [sensor_data_manually_generated](#sensor_data_manually_generated)

## sensor_data_is_from_git

Checks if unprocessed sensor data came from Github based on the  dataset's column names. Is a simplified check to be used when  comparing with manually generated sensor data. Checks if both  column components and order are equal to Git data columns. 

### Parameters

- **column_names**: A vector (char) of dataset column names.

### Returns

TRUE if data columns align with Github data columns, FALSE otherwise.

## sensor_data_manually_generated

Checks if unprocessed sensor data came from manual calibrations based on the  dataset's column names. Is a simplified check to be used when  comparing with sensor data from Github. Checks if both column components  and order are equal to manually calibrated data columns 

### Parameters

- **column_names**: A vector (char) of dataset column names.

### Returns

TRUE if data columns align with manually calibrated data  columns, FALSE otherwise.

