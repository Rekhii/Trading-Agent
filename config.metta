; Config for the MetaMo trading agent
; All tunable constants live here, following the repo convention of
; constants as nullary functions, so (ALPHA0) reads the value anywhere.

; Starting cash for both agents.
(= (INITIAL_CASH) 100.0)

; Series A: rise, crash, and a real recovery.
(= (PRICES) (10.0 11.0 12.0 13.0 14.0 13.0 11.5 10.0 9.0 10.0 11.0 12.0))

; Series B: same rise and crash, but the recovery is a trap. A brief
; bounce is followed by a second, deeper crash. The baseline re-buys
; the bounce and gets punished; the MetaMo agent's lingering caution
; keeps it out.
(= (PRICES_B) (10.0 11.0 12.0 13.0 14.0 13.0 11.5 10.0 9.0 10.0 11.0 9.0 8.0 7.0))

; Appraisal step sizes: how much one market event moves the modulators.
(= (APPR_UP)   0.12)
(= (APPR_DOWN) 0.15)
(= (VAL_DOWN)  0.10)

; Overgoal dynamics. The overgoals are now real state, not a formula:
; each step they track a target driven by capital health, and the
; reference point the agent judges itself against adapts slowly, so
; caution fades with time instead of freezing forever (habituation).
;   target_gInd   = clamp01(0.5 + STEEP * (1 - value/ref))
;   target_gTrans = clamp01(0.5 + STEEP * (value/ref - 1))
;   ref   <- ref + K_REF * (value - ref)         (slow habituation)
;   gInd  <- gInd + K_TRACK * (target - gInd)    (tracking)
; and a contrary market move cools the opposing drive a little:
;   rising market cools gInd, falling market cools gTrans.
(= (OVERGOAL_STEEP) 3.0)
(= (K_REF)   0.15)
(= (K_TRACK) 0.35)
(= (COOL)    0.10)

; Decision weights for the scoring equation, paper 2 Section 5.1 form,
; where the individuation penalty is scaled by the action's risk.
(= (W_GAIN) 1.0)
(= (W_PROT) 1.0)
(= (LAMBDA_IND)   0.8)
(= (LAMBDA_TRANS) 0.5)

; Incremental blend rate: alpha = ALPHA0*(1-gInd) + BETA0*gTrans.
(= (ALPHA0) 0.4)
(= (BETA0)  0.3)

; The six OpenPsi modulators, all starting neutral:
; (valence arousal approach resolution threshold securing)
(= (INITIAL_MODS) (0.5 0.5 0.5 0.5 0.5 0.5))

; Batch experiment settings: how many random markets and how long each.
(= (BATCH_RUNS) 30)
(= (BATCH_LEN)  25)
