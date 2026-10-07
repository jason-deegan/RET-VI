# RET-VI — Regional Energy Transition Vulnerability Index

RET-VI is a **data analytics and GIS visualisation platform** being developed to explore how regions may differ in their vulnerability to structural change associated with the energy transition.

The platform is being developed as part of the **RENOVATE project**, funded by the **Research Council of Norway (Norges forskningsråd)**. It combines data processing, indicator construction, geographical analysis and interactive visualisation to support the exploration of regional vulnerability.

RET-VI is designed as an analytical system rather than simply a composite index. The intended workflow connects:

**data → indicators → dimensions → index → geography → scenarios → interactive exploration**

## Current status

**RET-VI is currently at the demonstration/prototype stage.**

This public repository contains a fully reproducible demonstration version of the platform. It is intended to demonstrate the underlying analytical architecture, data structures and interactive GIS interface before the platform is connected to validated empirical data.

> **Important: all observations, weights, standardisation, geographic values and composite scores in the current demonstration are synthetic. They are included only to demonstrate the analytical architecture and user interface and must not be interpreted as empirical findings.**

The current demonstration includes:

- regional and municipality-level exploration;
- Exposure, Sensitivity and Adaptive Capacity dimensions;
- indicator-level evidence behind dimension scores;
- municipality comparison;
- exploratory grouping of multiple municipalities;
- methodological scenario testing;
- interactive maps and regional profiles;
- data and methodological transparency.

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
