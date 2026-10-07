# Validate the Stage 3A RET-VI indicator registry.
# This checks metadata integrity only; it does not judge substantive validity.

required <- c(
  "indicator_id", "indicator_name", "dimension", "concept", "description",
  "source", "source_version", "geography_type", "time_period", "unit",
  "direction", "aggregation_method", "standardisation_method", "provisional_weight",
  "status", "owner", "method_note", "data_quality_note"
)

registry_path <- file.path("data", "metadata", "ret_vi_indicator_registry.csv")
registry <- read.csv(registry_path, stringsAsFactors = FALSE, check.names = FALSE)

missing_columns <- setdiff(required, names(registry))
if (length(missing_columns) > 0) {
  stop("Missing required registry columns: ", paste(missing_columns, collapse = ", "))
}

if (anyDuplicated(registry$indicator_id)) {
  dupes <- unique(registry$indicator_id[duplicated(registry$indicator_id)])
  stop("Duplicate indicator_id values: ", paste(dupes, collapse = ", "))
}

allowed_dimensions <- c("Exposure", "Sensitivity", "Adaptive Capacity")
allowed_status <- c("candidate", "active", "placeholder", "retired")
allowed_direction <- c("positive", "negative", "context_dependent", "to_be_specified")
allowed_aggregation <- c("sum", "weighted_mean", "recompute", "none", "not_applicable", "to_be_specified")
allowed_standardisation <- c("min_max", "rank_percentile", "z_score", "robust_z_score", "none", "to_be_specified")

check_values <- function(x, allowed, field) {
  bad <- unique(x[!is.na(x) & nzchar(x) & !x %in% allowed])
  if (length(bad) > 0) {
    stop("Invalid values in ", field, ": ", paste(bad, collapse = ", "))
  }
}

check_values(registry$dimension, allowed_dimensions, "dimension")
check_values(registry$status, allowed_status, "status")
check_values(registry$direction, allowed_direction, "direction")
check_values(registry$aggregation_method, allowed_aggregation, "aggregation_method")
check_values(registry$standardisation_method, allowed_standardisation, "standardisation_method")

if (any(registry$status == "active" & registry$direction == "to_be_specified", na.rm = TRUE)) {
  stop("An active indicator cannot have direction = to_be_specified.")
}

cat("RET-VI Stage 3A indicator registry validation passed.\n")
cat("Indicators:", nrow(registry), "\n")
cat("Candidates:", sum(registry$status == "candidate"), "\n")
cat("Placeholders:", sum(registry$status == "placeholder"), "\n")
cat("Active:", sum(registry$status == "active"), "\n")
