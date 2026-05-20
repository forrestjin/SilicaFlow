# Silicon Test Layer

Store post-silicon test, bring-up, characterization, yield, and FA artifacts here.

Key reference note:

- [Wafer Binning In ASIC Silicon Test](../docs/silicon_test/wafer_binning.md)

Recommended ownership split:

- `dft/`: DFT intent and testability hooks
- `atpg/`: ATPG content, coverage, and diagnosis support
- `bringup/`: first-silicon and lab debug
- `characterization/`: shmoo, margin, and datasheet-correlation data
- `yield_reliability/`: wafer sort, binning, yield analytics, reliability screening, and sort-to-final-test correlation
- `fa/`: failure analysis and corrective-action closure
