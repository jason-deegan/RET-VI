# RET-VI Indicator Metadata Schema

This document defines the Stage 3A metadata contract for the RET-VI candidate indicator registry.

## Required fields

| Field | Meaning | Example |
|---|---|---|
| `indicator_id` | Stable machine-readable identifier | `energy_employment_share` |
| `indicator_name` | Human-readable label | `Employment share in transition-sensitive energy sectors` |
| `dimension` | RET-VI macro dimension | `Exposure` |
| `concept` | Substantive concept represented | `Transition-sensitive employment dependence` |
| `description` | Operational definition | Share of employment associated with defined sectors |
| `source` | Data origin | `R3-2026_NorceH&S` |
| `source_version` | Source release/version | `2026-03-27` |
| `geography_type` | Intended spatial resolution | `kommune` |
| `time_period` | Reference period | `2025` |
| `unit` | Measurement unit | `share` |
| `direction` | Relationship to vulnerability | `positive` / `negative` / etc. |
| `aggregation_method` | Geographic aggregation rule | `recompute` |
| `standardisation_method` | Candidate scaling method | `to_be_specified` |
| `provisional_weight` | Optional model placeholder | `NA` |
| `status` | Candidate lifecycle state | `candidate` |
| `owner` | Responsible work package/source | `RET-VI` / `WP1` / `WP2` |
| `method_note` | Methodological caveat or rationale | Free text |
| `data_quality_note` | Quality/coverage issue | Free text |

## Optional fields

The registry may later add:

- denominator definition;
- coverage start/end;
- suppression rule;
- source URL/reference;
- transformation formula;
- uncertainty estimate;
- spatial crosswalk version;
- temporal comparability flag;
- disclosure-control flag;
- duplicate/concept-overlap group;
- scenario eligibility.

## Identifier rule

`indicator_id` must remain stable once an indicator is activated. A substantive change in definition should normally produce a new version or new identifier rather than silently changing the meaning of an existing active indicator.
