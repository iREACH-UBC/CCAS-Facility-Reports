# A space to store report functions unused in current Rmd
# Includes functions for making timeseries plots, shading plot backgrounds, etc

generate_timeseries_plot <- function(
    pollutant_name, y_label_expression,
    outdoor_data_hr_avg, indoor_data_hr_avg) {
  # Get ranges first
  xrange <- range(c(outdoor_data_hr_avg$date, indoor_data_hr_avg$date))
  yrange <- range(
    c(
      outdoor_data_hr_avg[[pollutant_name]],
      indoor_data_hr_avg[[pollutant_name]]
    )
  )
  # Empty plot
  plot(NA,
    xlim = xrange, ylim = yrange,
    xlab = "Date",
    ylab = y_label_expression,
    xaxt = "n"
  )
  # Add title
  title(main = bquote(
    "Outdoor and Indoor" ~ .(y_label_expression[[1]]) ~ "vs Time"
  ))
  # Add grid lines
  grid(col = "#b9b9b9", lty = 1)
  # Add lines
  lines(
    outdoor_data_hr_avg$date, outdoor_data_hr_avg[[pollutant_name]],
    col = "blue"
  )
  lines(indoor_data_hr_avg$date,
    indoor_data_hr_avg[[pollutant_name]],
    col = "red"
  )
  # Format axis
  axis.POSIXct(
    1,
    indoor_data_hr_avg$date, # Assumes same dates in outdoor and indoor data
    format = "%b %d"
  )
  # Add legend
  legend(
    x = "topright", box.col = "black",
    bg = "#fafaa4", box.lwd = 2,
    legend = c(
      "Outdoor Concentrations",
      "Indoor Concentrations"
    ),
    fill = c("blue", "red")
  )
}

# Box plots for both indoor and outdoor datasets
get_box_plots <- function(
    outdoor_hr_avg_dataset, indoor_hr_avg_dataset, pollutant_name,
    y_label_expression) {
  box_outdoor <- ggplot(
    outdoor_hr_avg_dataset, aes(x = "", y = !!sym(pollutant_name))
  ) +
    geom_boxplot(fill = "blue") +
    labs(
      y = y_label_expression, x = "",
      main = bquote("Outdoor" ~ .(y_label_expression[[1]]) ~ "Distribution")
    ) +
    theme_minimal()
  box_indoor <- ggplot(
    indoor_hr_avg_dataset, aes(x = "", y = !!sym(pollutant_name))
    ) + geom_boxplot(fill = "red") +labs(
      y = y_label_expression, x = "",
      main = bquote("Outdoor" ~ .(y_label_expression[[1]]) ~ "Distribution")
    ) +
    theme_minimal()

  list("outdoor_plot" = box_outdoor, "indoor_plot" = box_indoor)
}

# Visual of CAAQS values for a pollutant
make_caaqs_legend <- function(
    legend_title,
    grn_val, ylw_val1, ylw_val2, org_val1,
    org_val2, red_val) {
  op <- par(no.readonly = TRUE)
  plot(
    0, 0,
    type = "n", axes = FALSE, xlab = "", ylab = "",
    xlim = c(0, 1), ylim = c(0, 1)
  )
  legend(
    "center",
    title = legend_title,
    legend = c(sprintf("Green (<=%s)", grn_val), sprintf(
      "Yellow (%s-%s)",
      ylw_val1, ylw_val2
    ), sprintf(
      "Orange (%s-%s)",
      org_val1, org_val2
    ), sprintf("Red (>%s)", red_val)),
    pch = 22,
    pt.bg = c("#187a1840", "#ffea0060", "#ff800040", "#ff000040"),
    col = "black",
    pt.cex = 2,
    bty = "n", cex = 0.8, xpd = NA
  )
  par(op)
}

# Modify if used, does not work for time change
remove_duplicate_times <- function(dataset) {
  duplicate_indices <- which(duplicated(dataset$date))

  if (length(duplicate_indices) > 0) {
    for (i in duplicate_indices) {
      avg_data_at_duplicate <- colMeans(
        dataset[(i - 1):i, 2:ncol(dataset)]
      )
      dataset[i - 1, 2:ncol(dataset)] <- avg_data_at_duplicate
      dataset <- dataset[-c(i), ]
    }
  }
  dataset
}

# This function has not been tested
get_uptime_pie_chart <- function(
  uptime_proportion, is_outdoor, month_char
) {
  if (is_outdoor) {
    location <- "outdoor"
  } else {
    location <- "indoor"
  }
  sensor_proportions <- c(uptime_proportion, 1 - uptime_proportion)
  labels <- c("Sensor uptime", "Sensor downtime")
  colours <- c("green", "red")
  pie(sensor_proportions, labels, col = colours,
    main = sprintf("Your %s sensor had %s uptime for %s.",
      location, uptime_proportion, month_char
    )
  )
}
