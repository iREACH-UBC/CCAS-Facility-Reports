# make_docs_markdown_auto.R

library(stringr)

# === CONFIG ===
input_file <- "libraries/time_processing_functions.R"  # only adjustable parameter

# --- Derive output file path ---
file_base <- tools::file_path_sans_ext(basename(input_file))
output_dir <- "docs/references"

# Check if the output directory exists before creating
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_file <- file.path(output_dir, paste0(file_base, "_ref.md"))

# --- Document title based on file name ---
title <- paste(str_to_title(str_replace_all(file_base, "_", " ")), "References")

# --- READ FILE ---
lines <- readLines(input_file)

# --- PARSE FUNCTION BLOCKS ---
blocks <- list()
current_block <- list(roxy = character(0), func_name = NULL)

for (i in seq_along(lines)) {
  line <- lines[i]
  if (grepl("^#'", line)) {
    current_block$roxy <- c(current_block$roxy, sub("^#' ?", "", line))
  } else if (grepl("^[a-zA-Z0-9_.]+ <- function\\(", line)) {
    current_block$func_name <- sub(" <-.*", "", line)
    blocks[[length(blocks) + 1]] <- current_block
    current_block <- list(roxy = character(0), func_name = NULL)
  }
}

# --- GENERATE MARKDOWN ---
md <- c(paste0("# ", title), "")

# Table of contents
md <- c(md, "## Table of Contents", "")
for (b in blocks) {
  md <- c(md, sprintf("- [%s](#%s)", b$func_name, b$func_name))
}
md <- c(md, "")

# Function sections
for (b in blocks) {
  md <- c(md, sprintf("## %s", b$func_name), "")
  
  # Split roxygen into tags and description
  tags_start <- which(grepl("^@", b$roxy))
  if (length(tags_start)) {
    description <- b$roxy[1:(tags_start[1]-1)]
    tags <- b$roxy[tags_start[1]:length(b$roxy)]
  } else {
    description <- b$roxy
    tags <- character(0)
  }
  
  # Overall description
  if (length(description)) {
    md <- c(md, paste(description, collapse = " "), "")
  }
  
  # Parse tags
  params <- list()
  returns <- NULL
  examples <- character(0)
  
  i <- 1
  while (i <= length(tags)) {
    line <- tags[i]
    if (grepl("^@param", line)) {
      m <- str_match(line, "^@param\\s+([a-zA-Z0-9_.]+)\\s*(.*)$")
      pname <- m[2]
      pdesc <- m[3]
      # capture continuation lines (indented)
      j <- i + 1
      while (j <= length(tags) && !grepl("^@", tags[j])) {
        pdesc <- paste(pdesc, tags[j])
        j <- j + 1
      }
      params[[pname]] <- pdesc
      i <- j - 1
    } else if (grepl("^@return", line)) {
      returns <- sub("^@return\\s+", "", line)
      j <- i + 1
      while (j <= length(tags) && !grepl("^@", tags[j])) {
        returns <- paste(returns, tags[j])
        j <- j + 1
      }
      i <- j - 1
    } else if (grepl("^@examples", line)) {
      examples <- tags[i:length(tags)]
      examples <- gsub("^\\s+", "", examples)
      break
    }
    i <- i + 1
  }
  
  # Parameters section
  if (length(params)) {
    md <- c(md, "### Parameters", "")
    for (pname in names(params)) {
      md <- c(md, sprintf("- **%s**: %s", pname, params[[pname]]), "")
    }
  }
  
  # Return
  if (!is.null(returns)) {
    md <- c(md, "### Returns", "", returns, "")
  }
  
  # Examples
  if (length(examples)) {
    md <- c(md, "### Examples", "", "```r", paste(examples, collapse = "\n"), "```", "")
  }
}

# --- WRITE MARKDOWN ---
writeLines(md, output_file)
message("Markdown documentation written to: ", output_file)
