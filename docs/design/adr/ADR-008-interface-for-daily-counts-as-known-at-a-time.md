# ADR-008: Interface for daily counts as known at a time

| | |
|---|---|
| Status | proposed |
| Date | 2026-11-17 |
| Requirement IDs | REQ-020 |
| Decided by | pending: a human decides at the architecture validation gate |

## Context
REQ-020 (RULE-119 to RULE-121) asks for a Layercake view or function that returns the daily count figures as they stood at a time T, for a date range, at the detail grain and at the silv_daily_count grain. The figure is today's stored figure minus the adjustments written strictly after T (Q-049). For a date first loaded after T, the first-load figures are returned (Q-050). A cell removed after T must still show its figure at T. The spec leaves the object kind and the interface to the design. Readers are analysts querying Layercake directly. Power BI work is out of scope.

## Options
### Option A: Two parameterised table functions
Layercake.fn_silv_daily_count_detail_as_known_at(@date_from, @date_to, @as_known_at) returns one row per detail cell. Layercake.fn_silv_daily_count_as_known_at with the same three parameters returns one row per ([date], region, grade), as the sum of the detail figures. Both read silv_daily_count_detail and silv_daily_count_adjustment at query time.

Trade-offs: This matches the spec's interface (a date range and a time T) exactly, so nobody writes the subtraction or the filters. Only the requested dates are read, and nothing is stored, so there is no extra load or storage. A function cannot be browsed as a table, and tools that only list views (for example a future Power BI model) would need a query wrapped around it. That does not matter in this release.

### Option B: Interval view of every figure version
A view returns one row per cell and figure version, with valid_from and valid_to written times: the version before the cell's first adjustment, then one version per adjustment. A reader filters on valid_from <= T < valid_to and on the date range.

Trade-offs: It can be browsed and joined like a table, and shows the whole history of a cell at once. But it has to rebuild the versions from today's figure backwards for every cell it touches. Each query that does not filter tightly on dates expands the whole spine. The reader has to apply the T boundary correctly, which is the hand-written step REQ-020 wants to remove. And the silv_daily_count grain would need a second view whose versions combine the cells' intervals, which is harder to get right.

## Recommendation
Option A: Two parameterised table functions. The spec describes a query by date range and time T, and a table function is exactly that. It keeps the T boundary (strictly after T) and the zero-for-missing-cell rule in one place, and reads only the requested dates. The interval view adds browsing that nobody has asked for, at the cost of performance and of putting the boundary logic back in the reader's hands.

## Decision
Pending: filled in by a human at the architecture validation gate.

## Consequences
MOD-021 builds Layercake.fn_silv_daily_count_detail_as_known_at and Layercake.fn_silv_daily_count_as_known_at alongside the adjustment table and the review view Layercake.vw_silv_daily_count_adjustment_review, which is a view because it takes no parameters. The grant script gives the reporting role SELECT on the two functions and the view. If the interval view is chosen instead, MOD-021 builds two views in place of the functions, and the AC-020 tests filter the views on T.
