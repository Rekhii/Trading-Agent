; baseline.metta
; The BASELINE agent (mentor's option 1): a fixed-rule momentum trader
; with NO MetaMo machinery at all - no modulators, no overgoals, no
; emotions. It trades the same price series with the same actions as
; the MetaMo agent, so any difference in behavior between the two is
; attributable to MetaMo.
;
; Its whole strategy, forever, regardless of how it has been doing:
;     price went UP   since last step  -> Buy
;     price went DOWN since last step  -> Sell
;     price unchanged                  -> Hold

; (baselineDecide $priceChange) -> Buy | Sell | Hold
; $priceChange is (currentPrice - lastPrice).
(= (baselineDecide $priceChange)
   (if (> $priceChange 0.0)
       Buy
       (if (< $priceChange 0.0) Sell Hold)))

; (execAction $action $cash $shares $price) -> ($newCash $newShares)
; Shared by BOTH agents so the market rules are identical:
;   Buy  : spend $price for 1 share, only if we can afford it
;   Sell : receive $price for 1 share, only if we hold any
;   Hold : do nothing
; If a Buy/Sell is not possible it silently becomes a Hold, so the
; agent can never go negative on cash or shares.
(= (execAction Buy $cash $shares $price)
   (if (>= $cash $price)
       ((- $cash $price) (+ $shares 1))
       ($cash $shares)))
(= (execAction Sell $cash $shares $price)
   (if (> $shares 0)
       ((+ $cash $price) (- $shares 1))
       ($cash $shares)))
(= (execAction Hold $cash $shares $price)
   ($cash $shares))

; (effectiveAction $action $cash $shares $price) -> the action that will
; ACTUALLY happen after the affordability guards above. A Buy without
; cash or a Sell without shares is really a Hold, and the log should
; say so rather than print an intention that had no effect.
(= (effectiveAction Buy $cash $shares $price)
   (if (>= $cash $price) Buy Hold))
(= (effectiveAction Sell $cash $shares $price)
   (if (> $shares 0) Sell Hold))
(= (effectiveAction Hold $cash $shares $price)
   Hold)

; (portfolioValue $cash $shares $price) -> total value right now
(= (portfolioValue $cash $shares $price)
   (+ $cash (* $shares $price)))

; (baselineRun $prices $lastPrice $cash $shares $step)
; Walks the remaining price list recursively, printing one line per
; step:   (BASELINE step N price P action A value V)
; Returns the final portfolio value when the series ends.
(= (baselineRun $prices $lastPrice $cash $shares $step)
   (if (== $prices ())
       (portfolioValue $cash $shares $lastPrice)
       (let* (($price  (car-atom $prices))
              ($remainingPrices   (cdr-atom $prices))
              ($priceChange  (- $price $lastPrice))
              ($intendedAction (baselineDecide $priceChange))
              ($action (effectiveAction $intendedAction $cash $shares $price))
              ($cashAndShares     (execAction $action $cash $shares $price))
              ($newCash  (car-atom $cashAndShares))
              ($newShares    (car-atom (cdr-atom $cashAndShares)))
              ($value    (portfolioValue $newCash $newShares $price))
              ($_      (println! (BASELINE step $step price $price action $action value $value))))
         (baselineRun $remainingPrices $price $newCash $newShares (+ $step 1)))))

; Quiet run for the batch experiment: same loop, no printing.
(= (baselineRunQ $prices $lastPrice $cash $shares)
   (if (== $prices ())
       (portfolioValue $cash $shares $lastPrice)
       (let* (($price  (car-atom $prices))
              ($remainingPrices   (cdr-atom $prices))
              ($priceChange  (- $price $lastPrice))
              ($intendedAction (baselineDecide $priceChange))
              ($action (effectiveAction $intendedAction $cash $shares $price))
              ($cashAndShares     (execAction $action $cash $shares $price))
              ($newCash  (car-atom $cashAndShares))
              ($newShares    (car-atom (cdr-atom $cashAndShares))))
         (baselineRunQ $remainingPrices $price $newCash $newShares))))
