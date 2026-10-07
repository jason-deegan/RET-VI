# RET-VI — Regional Energy Transition Vulnerability Index

RET-VI is a research-software prototype for exploring how regions may differ in their vulnerability to structural change associated with the energy transition.

The project is designed as an analytical system rather than simply a composite score. The intended workflow connects:

**data → indicators → dimensions → index → geography → scenarios → interactive exploration**

## Public demonstration

This public repository contains a **fully reproducible demonstration version** of RET-VI.

> **Important: all observations, weights, standardisation, geographic values and composite scores in the current demonstration are synthetic. They are included only to demonstrate the analytical architecture and user interface and must not be interpreted as empirical findings.**

The application currently demonstrates:

- regional and municipality-level exploration;
- Exposure, Sensitivity and Adaptive Capacity dimensions;
- indicator-level evidence behind dimension scores;
- municipality comparison;
- exploratory grouping of multiple municipalities;
- methodological scenario testing;
- data and method transparency;
- interactive maps and profiles.

## Analytical architecture

```text
Synthetic demonstration data
            ↓
      Indicator layer
            ↓
 Exposure / Sensitivity /
   Adaptive Capacity
            ↓
       RET-VI score
            ↓
 Geography + scenarios
            ↓
       Shiny interface
```

The repository is structured so that the demonstration can later be connected to validated empirical data without rebuilding the application from scratch.

## Technical stack

- **R**
- **Shiny**
- **bslib**
- **leaflet**
- **ggplot2**
- **csmaps** for the demonstration geography layer
- YAML configuration for model, indicator, geography and scenario definitions

## Repository structure

```text
app/       Shiny application
R/         Reusable analytical functions and validation code
config/    Machine-readable configuration
 data/     Synthetic demonstration data and metadata
docs/      Public methodology and data documentation
tests/     Automated checks
outputs/   Generated outputs
```

## Run locally

The demonstration application is self-contained.

Install the required R packages:

```r
install.packages(c("shiny", "bslib", "leaflet", "ggplot2", "csmaps"))
```

Then run:

```r
shiny::runApp("app/prototype")
```

## Development status

**Current status: research-software prototype / demonstration version.**

The public version is intended to demonstrate the architecture and functionality of RET-VI. The final indicator set, weighting scheme, aggregation method and empirical data sources are not fixed by this repository.

## Why synthetic data?

The public demonstration uses synthetic observations so that the complete application can be shared and reproduced without distributing restricted or project-specific empirical data.

The synthetic data preserves the structure needed to demonstrate the workflow, but the resulting values have no substantive interpretation.

## Project context

RET-VI was developed in the context of research on regional vulnerability and energy transition. The public repository focuses on the technical and analytical architecture of the demonstration rather than reproducing project-internal development materials.
