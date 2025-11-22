og_csv_dir <- "test_indoor2/March2026/TEST2.csv"
new_csv_dir <- "test_indoor2/March2026/TEST1.csv"

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