; decision.metta
; The DECISION step (D) of the MetaMo cycle: score every action and
; pick the best one. The scoring follows paper 2 (Section 5.1 form,
; where the individuation penalty is scaled by the action's risk):
;
;   score(a) =   W_GAIN * gGain * mGain * corrGain(a)
;              + W_PROT * gProt * mProt * corrProt(a)
;              - LAMBDA_IND   * gInd   * risk(a)
;              + LAMBDA_TRANS * gTrans * bold(a)
;
; The two primary goals and their modulators:
;   gain-seeking goal  gGain = gTrans, modulator = approach
;   protect-capital    gProt = gInd,   modulator = securing
;
; corr(a, g) is the piece the paper leaves to us. Here it is defined
; from what each action does in the market, with a momentum flavour:
; buying fits the gain goal better when the price is rising, selling
; fits the protect goal better when the price is falling.

; (corrGain $action $priceChange) -> [0,1]
(= (corrGain Buy  $priceChange) (if (> $priceChange 0.0) 0.9 0.5))  ; buying chases gains
(= (corrGain Sell $priceChange) 0.1)                          ; selling doesn't
(= (corrGain Hold $priceChange) 0.2)

; (corrProt $action $priceChange) -> [0,1]
(= (corrProt Buy  $priceChange) 0.1)                          ; buying exposes capital
(= (corrProt Sell $priceChange) (if (< $priceChange 0.0) 0.9 0.5))  ; selling protects it
(= (corrProt Hold $priceChange) 0.6)                          ; holding is safe-ish

; risk feeds the individuation penalty, bold feeds the transcendence bonus.
(= (risk Buy)  0.8)
(= (risk Sell) 0.1)
(= (risk Hold) 0.2)
(= (bold Buy)  1.0)
(= (bold Sell) 0.0)
(= (bold Hold) 0.2)

; (scoreAction $action $priceChange $modulators $gInd $gTrans) -> number
; Pulls approach and securing out of the modulator vector and applies
; the four-term score above (all arithmetic nested binary for PeTTa).
(= (scoreAction $action $priceChange $modulators $gInd $gTrans)
   (let ($valence $arousal $approach $resolution $threshold $securing) $modulators
     (+ (+ (* (* (W_GAIN) (* $gTrans $approach)) (corrGain $action $priceChange))
           (* (* (W_PROT) (* $gInd $securing))  (corrProt $action $priceChange)))
        (+ (- 0.0 (* (* (LAMBDA_IND) $gInd) (risk $action)))
           (* (* (LAMBDA_TRANS) $gTrans) (bold $action))))))

; (decide $priceChange $modulators $gInd $gTrans) -> Buy | Sell | Hold
; Scores all three actions and returns the highest-scoring one.
; Ties are broken in the safe direction (Hold beats Sell beats Buy on
; equal scores), which only matters in degenerate flat markets.
(= (decide $priceChange $modulators $gInd $gTrans)
   (let* (($scoreBuy (scoreAction Buy  $priceChange $modulators $gInd $gTrans))
          ($scoreSell (scoreAction Sell $priceChange $modulators $gInd $gTrans))
          ($scoreHold (scoreAction Hold $priceChange $modulators $gInd $gTrans)))
     (if (and (> $scoreBuy $scoreSell) (> $scoreBuy $scoreHold))
         Buy
         (if (> $scoreSell $scoreHold) Sell Hold))))
