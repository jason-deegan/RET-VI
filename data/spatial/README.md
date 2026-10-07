# RET-VI spatial data layer — Stage 3B

The spatial layer makes geography a first-class part of RET-VI. The primary portal geography is **kommune**. Fylke provides higher-level context, while arbeidsmarkedsregion is an additional analytical geography where an agreed source definition exists.

## Rules

- Join production data using stable geography IDs, not names.
- Current/recent authoritative boundaries are the default portal geometry.
- Historical source data may require a documented crosswalk to current boundaries.
- Do not manufacture kommune-level precision from a source available only at fylke/AMR level.
- Aggregation depends on the indicator: additive quantities can generally be summed; rates/shares should be weighted or recomputed; derived indices require their own documented method; some indicators should not be aggregated.

The files currently in this directory are **architecture/examples**, not authoritative production geography.
