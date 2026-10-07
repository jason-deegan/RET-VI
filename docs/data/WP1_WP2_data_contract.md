# RET-VI WP1/WP2 Data Contract

## Purpose

This document defines the interface between WP1/WP2 analytical outputs and the RET-VI system.

The files in `data/wp1/` and `data/wp2/` are placeholders at this stage. They establish the expected structure and must not be interpreted as substantive results.

## Required observation fields

- `geography_id`: stable geographic identifier.
- `geography_type`: e.g. `kommune`, `arbeidsmarkedsregion`, `fylke`.
- `geography_name`: human-readable name; the stable ID is authoritative.
- `year`: reference year.
- `indicator_id`: stable identifier for the indicator.
- `indicator_name`: human-readable indicator name.
- `value`: numeric indicator value.
- `unit`: unit or scale.
- `source`: `WP1` or `WP2`.
- `source_version`: version/date identifying the supplied dataset.
- `method_note`: short description or pointer to the method used.
- `coverage_start`, `coverage_end`: optional coverage period.
- `quality_flag`: e.g. `observed`, `estimated`, `placeholder`, `suppressed`.
- `suppression_flag`: whether the value is suppressed/confidential.
- `notes`: additional information needed for interpretation.

## Rules

1. `indicator_id` must remain stable once adopted by RET-VI.
2. `geography_id` must be supplied wherever possible; names are not sufficient as the join key.
3. Missing values should be represented as missing (`NA`), not zero, unless zero is substantively meaningful.
4. A placeholder must never be represented as a substantive numeric result.
5. Changes in methodology or definition should generate a new `source_version` and be documented in `method_note`.
6. WP1/WP2 should provide a dictionary alongside the observation file.
7. RET-VI will not assume that an indicator is vulnerability-increasing or vulnerability-decreasing until its direction has been explicitly documented.
8. Geographic harmonisation will be handled by the RET-VI geography layer rather than manual name matching.

## Minimal handover

A production handover consists of:

- one observation table;
- one indicator dictionary;
- a source/method note;
- version/date information;
- geographic coverage information.
