packages <- c(
  "rmarkdown", "knitr", "tinytex", "languageserver",
  "R.methodsS3", "R.oo", "R.utils", "R.cache",
  "collections", "lintr", "styler", "xmlparsedata",
  "latticeExtra", "patchwork", "worldmet", "readxl",
  "openair", "gtools", "caret", "plyr", "kableExtra",
  "writexl", "grid", "gridExtra", "lattice", "png",
  "styler", "jsonlite", "zoo", "roxygen2", "testthat",
  "patrick", "modules"
)

# Check which packages are missing
installed <- rownames(installed.packages())
to_install <- setdiff(packages, installed)

if(length(to_install)) {
  print(paste("Installing missing packages:", paste(to_install, collapse = ", ")))
  install.packages(to_install)
} else {
  print("All packages already installed, skipping install.")
}

# TinyTeX requires separate check
if (!tinytex::is_tinytex()) {
  print("Installing TinyTeX...")
  tinytex::install_tinytex(force = TRUE)
} else {
  print("TinyTeX already installed, skipping.")
}

# Install captioner from archives
install.packages("https://cran.r-project.org/src/contrib/Archive/captioner/captioner_2.2.3.tar.gz", 
repos = NULL, type = "source")

print("Finished package installations")