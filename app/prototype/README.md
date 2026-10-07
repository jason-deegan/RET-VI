# RET-VI demonstration application

A self-contained Shiny demonstration of the RET-VI analytical interface.

## What it demonstrates

- map-based regional exploration;
- municipality profiles;
- Exposure, Sensitivity and Adaptive Capacity dimensions;
- indicator-level evidence;
- municipality comparison;
- exploratory multi-municipality grouping;
- methodological scenarios;
- data and method transparency.

## Data note

All observations, geography values, weights, standardisation and composite calculations are synthetic placeholders. They have **no empirical meaning**.

The application is intended to demonstrate the analytical workflow and interface before validated empirical data are integrated.

## Run locally

```r
install.packages(c("shiny", "bslib", "leaflet", "ggplot2", "csmaps"))
shiny::runApp("app/prototype")
```
