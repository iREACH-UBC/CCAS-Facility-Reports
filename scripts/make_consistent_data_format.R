# A script to pre-process files with time shift and without aqhi
# Gets files to github file format
time_shift_hrs <- 14

qaq_files <- c(
  "test/2049.csv"
)

for (file in qaq_files) {
  qaq_df <- read.csv(file)

  qaq_df$date <- ifelse(
    grepl(":", qaq_df$date),
    qaq_df$date,
    paste0(qaq_df$date, " 00:00") # add midnight if missing
  )

  qaq_df$date <- as.POSIXct(qaq_df$date, format = "%Y-%m-%d %H:%M", tz = "US/Pacific")
  qaq_df$date <- qaq_df$date - (time_shift_hrs*3600)

  last_sept_index <- tail(grep("2025-09-30", qaq_df$date), 1)
  print(last_sept_index)
  if (!(is.null(last_sept_index))) {
    qaq_df <- qaq_df[(last_sept_index+1):nrow(qaq_df), ]
  }
  first_nov_index <- grep("2025-11-01", qaq_df$date)
  print(first_nov_index)
#   print(first_nov_index + length(1:last_sept_index))
  if (!(is.null(first_nov_index))) {
    qaq_df <- qaq_df[1:(first_nov_index-1), ]
  }
  write.csv(qaq_df, file, row.names = FALSE, quote = FALSE)
  print(sprintf("Wrote csv for %s", file))
}
