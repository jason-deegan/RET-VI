# RET-VI Stage 3B — Geography specification

**Status:** Working specification
**Version:** 0.1
**Date:** 2026-09-22

## 1. Purpose

Stage 3B establishes the geography layer required for RET-VI to operate consistently across indicators, maps, regional profiles and later aggregation/scenario functions.

The key principle is that geography is not merely a map layer. It is part of the analytical data model. Every indicator observation must be interpretable in relation to a defined geography, geography version and transformation history.

## 2. Geography hierarchy

```text
Kommune
   │
   ├── Fylke (higher-level context)
   │
   └── Arbeidsmarkedsregion (additional analytical geography)
```

### Kommune
The kommune is the **primary spatial unit** for the RET-VI portal and the default unit for indicator presentation where the underlying data support it.

### Fylke
Fylke is retained as a higher-level contextual and analytical unit. It should support comparison and aggregation without replacing the kommune-level view.

### Arbeidsmarkedsregion
Arbeidsmarkedsregion is an additional analytical unit. It is particularly relevant where labour-market dynamics and WP1/WP2 outputs are better represented by functional labour-market areas than administrative boundaries. The exact definition/version must be documented when activated.

## 3. Stable identifiers

Production joins must use stable geography IDs. Names are labels and may change; they are not sufficient as primary keys.

The geography metadata layer therefore records:

- geography ID
- geography type
- geography name
- boundary version
- role in RET-VI
- source
- status

## 4. Boundary versions

The portal should use a current/recent authoritative boundary version as its default. Historical boundaries are not ignored, but historical source data should be transformed only where the transformation is defensible and documented.

The project does not need a universal historical geography engine at this stage. Source-specific cases can be handled through explicit crosswalks.

## 5. Crosswalks

A crosswalk records how an observation moves from one geography system to another. Minimum metadata:

| Field | Purpose |
|---|---|
| source_geography_type | Original spatial level |
| source_geography_id | Original ID |
| target_geography_type | Target spatial level |
| target_geography_id | Target ID |
| transformation_method | Direct, sum, weighted, recompute, etc. |
| weight | Allocation/aggregation weight where applicable |
| weight_basis | Population, employment, area, etc. |
| source_version | Source geography/data version |
| target_boundary_version | Target geography version |
| notes | Human-readable explanation |

The architecture supports direct mappings, weighted crosswalks and indicator-specific transformations without assuming that one method works for every source.

## 6. Aggregation rules

Geographic aggregation is separate from the final RET-VI mathematical aggregation.

### Additive quantities
Counts, employment volumes and other genuinely additive quantities may generally be summed.

### Rates and shares
Rates/shares should normally be recomputed from the underlying numerator/denominator or combined using an appropriate denominator-weighted mean. A simple arithmetic mean of municipality percentages is usually not an appropriate regional aggregate.

### Derived indices
Location quotients, indices and other derived measures should normally be recomputed from the underlying components, or aggregated using an explicitly justified method.

### Non-aggregatable indicators
Some measures should remain at their source geography. These must be flagged rather than silently transformed.

## 7. Precision rule

If a source is available only at fylke level, RET-VI will not create apparently precise kommune values by distributing the value without a documented basis. Such observations remain at their source resolution unless a defensible transformation is established.

This rule is particularly important for the eventual portal: missingness caused by geography should be visible as a data limitation, not disguised as estimated precision.

## 8. Current example data

The repository contains a small illustrative geography table and kommune-to-fylke example crosswalk. These are **placeholders only** and must be replaced by authoritative production geography before analytical use.
