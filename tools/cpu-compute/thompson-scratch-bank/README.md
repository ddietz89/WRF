# Thompson per-call scratch bank

Combine 79 automatic DOUBLE PRECISION arrays with identical vertical bounds into one per-call array. [SLOTS.json](SLOTS.json) retains each original name and its column. The first dimension remains the vertical index; there is no persistent workspace or cross-call sharing.

The working fork includes this change after eleven current-parent complete native cases at O0/bounds and strict O2, then the combined MYJPBL + bank three-hour full-grid check: all four products and 545 ordered steps passed the unchanged exact checker. The [joint qualification](../myj-thompson-bank/QUALIFICATION.json) records receipts, source/object hashes and scope.

Current opposite-order complete-caller observations were 1.1198% shorter and 1.8676% longer. Earlier parent observations were 0.3523% and 1.4828% shorter. Current performance remains unresolved. The change removes 78 allocation/free sites and 75 memset sites in the measured native routine, with 5,584 additional bytes of routine text. It has no established forecast speedup. Inclusion retains the demonstrated allocation mechanism and prior local gains under the owner policy; the latest combined run is scientific qualification, not an isolated performance measurement.

Revert the dedicated scratch-bank source commit to restore all original names/declarations, retaining MYJPBL. The exact position-aware inverse and native/caller evidence remain in `investigation/wrf-cpu/campaign/spot100-20261016/thompson-bank-current-port-r1` in the campaign workspace. The retained `7cab913b` executable with the same pinned runtime rolls back both new additions immediately. Production and master are unchanged.
