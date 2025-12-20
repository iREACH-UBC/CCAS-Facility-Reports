og_csv_dir <- "test_indoor2/November2025/2020.csv"
new_csv_dir <- "indoor_data_processed/November2025/2020.csv"

og_csv <- read.csv(og_csv_dir)
new_csv <- read.csv(new_csv_dir)

print(all.equal(og_csv, new_csv))

indices_of_date_difference <- which(
  og_csv$date != new_csv$date
)
if (length(indices_of_date_difference) != 0) {
  print(og_csv$date[indices_of_date_difference])
  print(new_csv$date[indices_of_date_difference])
}