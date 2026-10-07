# Validate the WP1/WP2 data contract

required_columns <- c(
  "geography_id", "geography_type", "geography_name", "year",
  "indicator_id", "indicator_name", "value", "unit",
  "source", "source_version", "method_note",
  "coverage_start", "coverage_end", "quality_flag",
  "suppression_flag", "notes"
)

validate_wp_dataset <- function(path, expected_source) {
  x <- read.csv(path, na.strings = c("", "NA"), stringsAsFactors = FALSE)

  missing_columns <- setdiff(required_columns, names(x))
  if (length(missing_columns) > 0) {
    stop(sprintf("%s is missing required columns: %s",
                 basename(path), paste(missing_columns, collapse = ", ")))
  }

  if (!all(x$source == expected_source)) {
    stop(sprintf("%s contains an unexpected source value.", basename(path)))
  }

  if (anyDuplicated(x[c("geography_id", "geography_type", "year", "indicator_id")])) {
    stop(sprintf("%s contains duplicate indicator observations.", basename(path)))
  }

  invisible(x)
}

validate_wp_dataset("data/wp1/wp1_indicators_placeholder.csv", "WP1")
validate_wp_dataset("data/wp2/wp2_indicators_placeholder.csv", "WP2")

message("WP1/WP2 data-contract validation passed.")
