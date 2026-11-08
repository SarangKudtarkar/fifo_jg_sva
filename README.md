# FIFO Formal Verification (JasperGold SVA style)

Parameterized synchronous FIFO plus a bound SVA checker.

## Files

- rtl/fifo.sv              DUT
- formal/fifo_sva.sv       SVA checker (assert / assume / cover + scoreboard)
- formal/fifo_bind.sv      bind of checker into fifo
- scripts/fifo_formal.tcl  JasperGold script

## Run

From the repository root:

    jg -allow_unsupported_OS scripts/fifo_formal.tcl   (or: jg, then source scripts/fifo_formal.tcl)

## Notes

- Inputs (wr_en, rd_en, wr_data) are left free, as is default in JasperGold.
- sym_data is an undriven signal in the checker, treated as a free input and
  constrained with a $stable assume (symbolic constant).
- The scoreboard tags the first write of sym_data, counts entries ahead of it,
  and asserts rd_data == sym_data one cycle after it is read (registered output).
- If your JG version warns about the undriven sym_data, that is expected;
  you can also pin it with `stopat` in the TCL.
- Review the cover results first: a vacuous cover means the assertions
  are not exercising the interesting behavior.
