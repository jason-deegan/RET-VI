# Stage 3A Indicator Registry

The authoritative Stage 3A candidate registry is:

`data/metadata/ret_vi_indicator_registry.csv`

It is intentionally broader than the eventual active RET-VI indicator set.

## How to use it

- Add candidate indicators without changing the meaning of existing IDs.
- Keep `status = candidate` until conceptual, data and methodological tests have been completed.
- Use `status = placeholder` only for WP1/WP2 interface entries that do not yet have substantive definitions.
- Do not populate missing values with zero.
- Do not assign final weights simply because a numeric weight field exists.
- Keep source and version information explicit.

The registry is metadata, not the analytical dataset. Observations will continue to live in source/processed data structures under the data contract established in Stage 1/2.
