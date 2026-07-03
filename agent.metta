; Agent loop for the MetaMo trading agent
; One step runs F = D o Psi with the incremental blend:
;   1 update the reference point and the two overgoals (state now,
;     with tracking, cooling and habituation - see appraisal.metta)
;   2 appraisal Psi: market delta -> target modulators
;   3 blend: mods move only partway toward the target,
;     alpha = ALPHA0*(1-gInd) + BETA0*gTrans (paper 2)
;   4 decision D: score Buy/Sell/Hold, pick best (decision.metta)
;   5 execute in the market, same rules as the baseline

; Blend the whole modulator vector element-wise.
(= (blendMods $old $targetModulators $alpha)
   (let ($oldValence $oldArousal $oldApproach $oldResolution $oldThreshold $oldSecuring) $old
     (let ($targetValence $targetArousal $targetApproach $targetResolution $targetThreshold $targetSecuring) $targetModulators
       ((blend2 $oldValence  $targetValence  $alpha)
        (blend2 $oldArousal  $targetArousal  $alpha)
        (blend2 $oldApproach $targetApproach $alpha)
        (blend2 $oldResolution  $targetResolution  $alpha)
        (blend2 $oldThreshold  $targetThreshold  $alpha)
        (blend2 $oldSecuring  $targetSecuring  $alpha)))))

; The blend rate from the overgoals, paper 2.
(= (blendAlpha $gInd $gTrans)
   (+ (* (ALPHA0) (- 1.0 $gInd)) (* (BETA0) $gTrans)))

; One shared MetaMo step. Takes the whole state, returns the new
; state as (cash shares mods gInd gTrans ref action value emotion).
(= (metamoStep $price $priceChange $cash $shares $modulators $gInd $gTrans $reference)
   (let* (($currentValue  (portfolioValue $cash $shares $price))
          ($newReference    (refStep $reference $currentValue))
          ($valueRatio   (/ $currentValue $newReference))
          ($newGInd     (overgoalStep $gInd (gIndTarget $valueRatio)   (> $priceChange 0.0)))
          ($newGTrans     (overgoalStep $gTrans (gTransTarget $valueRatio) (< $priceChange 0.0)))
          ($targetModulators  (appraise $modulators $priceChange $newGInd $newGTrans))
          ($alpha   (blendAlpha $newGInd $newGTrans))
          ($newModulators   (blendMods $modulators $targetModulators $alpha))
          ($emotion     (emotionOf $newModulators))
          ($intendedAction  (decide $priceChange $newModulators $newGInd $newGTrans))
          ($action  (effectiveAction $intendedAction $cash $shares $price))
          ($cashAndShares      (execAction $action $cash $shares $price))
          ($newCash   (car-atom $cashAndShares))
          ($newShares     (car-atom (cdr-atom $cashAndShares)))
          ($value     (portfolioValue $newCash $newShares $price)))
     ($newCash $newShares $newModulators $newGInd $newGTrans $newReference $action $value $emotion)))

; Verbose run: prints one line per step, returns the final value.
(= (metamoRun $prices $lastPrice $cash $shares $modulators $gInd $gTrans $reference $step)
   (if (== $prices ())
       (portfolioValue $cash $shares $lastPrice)
       (let* (($price (car-atom $prices))
              ($remainingPrices  (cdr-atom $prices))
              ($priceChange (- $price $lastPrice))
              ($newState    (metamoStep $price $priceChange $cash $shares $modulators $gInd $gTrans $reference))
              (($newCash $newShares $newModulators $newGInd $newGTrans $newReference $action $value $emotion) $newState)
              ($face  (moodFace $emotion))
              ($_     (println! (METAMO step $step price $price emotion $emotion face $face gInd $newGInd gTrans $newGTrans action $action value $value))))
         (metamoRun $remainingPrices $price $newCash $newShares $newModulators $newGInd $newGTrans $newReference (+ $step 1)))))

; Quiet run for the batch experiment: same loop, no printing.
(= (metamoRunQ $prices $lastPrice $cash $shares $modulators $gInd $gTrans $reference)
   (if (== $prices ())
       (portfolioValue $cash $shares $lastPrice)
       (let* (($price (car-atom $prices))
              ($remainingPrices  (cdr-atom $prices))
              ($priceChange (- $price $lastPrice))
              ($newState    (metamoStep $price $priceChange $cash $shares $modulators $gInd $gTrans $reference))
              (($newCash $newShares $newModulators $newGInd $newGTrans $newReference $action $value $emotion) $newState))
         (metamoRunQ $remainingPrices $price $newCash $newShares $newModulators $newGInd $newGTrans $newReference))))
