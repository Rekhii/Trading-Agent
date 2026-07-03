; Main entry point for the trading agent comparison
; Runs both agents on series A and series B, then the batch experiment
; over random markets. Run from this folder with:
;   sh ~/PeTTa/run.sh main.metta

!(import! &self config.metta)
!(import! &self helpers.metta)
!(import! &self baseline.metta)
!(import! &self appraisal.metta)
!(import! &self emotion.metta)
!(import! &self decision.metta)
!(import! &self agent.metta)
!(import! &self batch.metta)

; Series A: recovery is real.
!(println! (=== SERIES A - BASELINE ===))
!(println! (BASELINE_FINAL_VALUE
   (baselineRun (PRICES) 10.0 (INITIAL_CASH) 0 1)))
!(println! (=== SERIES A - METAMO ===))
!(println! (METAMO_FINAL_VALUE
   (metamoRun (PRICES) 10.0 (INITIAL_CASH) 0 (INITIAL_MODS) 0.5 0.5 (INITIAL_CASH) 1)))

; Series B: the recovery is a trap.
!(println! (=== SERIES B - BASELINE ===))
!(println! (BASELINE_B_FINAL_VALUE
   (baselineRun (PRICES_B) 10.0 (INITIAL_CASH) 0 1)))
!(println! (=== SERIES B - METAMO ===))
!(println! (METAMO_B_FINAL_VALUE
   (metamoRun (PRICES_B) 10.0 (INITIAL_CASH) 0 (INITIAL_MODS) 0.5 0.5 (INITIAL_CASH) 1)))

; Batch: many random markets, distribution of outcomes.
!(println! (=== BATCH EXPERIMENT - RANDOM MARKETS ===))
!(println! (BATCH_SUMMARY (runBatch)))
