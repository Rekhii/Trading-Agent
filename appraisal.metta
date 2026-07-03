; Appraisal for the MetaMo trading agent
; The Psi step of the MetaMo cycle plus the overgoal dynamics.
; Modulator vector order, fixed everywhere in this project:
; (valence arousal approach resolution threshold securing)

; Overgoal targets from capital health. ratio = value / reference.
; Steeper than a 1:1 mapping so the overgoals use their full range
; instead of hovering near neutral.
(= (gIndTarget $ratio)
   (clamp01 (+ 0.5 (* (OVERGOAL_STEEP) (- 1.0 $ratio)))))
(= (gTransTarget $ratio)
   (clamp01 (+ 0.5 (* (OVERGOAL_STEEP) (- $ratio 1.0)))))

; One step of overgoal dynamics: track the target, then let a market
; move that contradicts the drive cool it slightly toward neutral.
; A rising market cools gInd (courage returns); a falling market
; cools gTrans (enthusiasm fades). This is what lets caution decay
; instead of freezing after a crash.
(= (overgoalStep $overgoal $target $contrary)
   (let $trackedOvergoal (+ $overgoal (* (K_TRACK) (- $target $overgoal)))
     (if $contrary
         (+ $trackedOvergoal (* (COOL) (- 0.5 $trackedOvergoal)))
         $trackedOvergoal)))

; The slowly adapting reference point (habituation): the value the
; agent measures itself against drifts toward the current value, so
; after enough time at a new level, that level starts to feel normal.
(= (refStep $reference $currentValue)
   (+ $reference (* (K_REF) (- $currentValue $reference))))

; Appraisal of one market step: updates the six modulators from the
; price move, scaled by the overgoals as in paper 2. A flat step
; leaves the modulators unchanged.
(= (appraise $modulators $priceChange $gInd $gTrans)
   (if (== $priceChange 0.0)
       $modulators
   (let ($valence $arousal $approach $resolution $threshold $securing) $modulators
     (if (> $priceChange 0.0)
         ; Favourable move: encouragement, scaled up by gTrans.
         (let $bump (* (APPR_UP) (+ 0.5 $gTrans))
           ((clamp01 (+ $valence $bump))
            (clamp01 (+ $arousal $bump))
            (clamp01 (+ $approach $bump))
            $resolution
            (clamp01 (- $threshold (* 0.5 $bump)))
            (clamp01 (- $securing (* 0.5 $bump)))))
         ; Unfavourable move: caution, scaled up by gInd.
         (let $bump (* (APPR_DOWN) (+ 0.5 $gInd))
           ((clamp01 (- $valence (VAL_DOWN)))
            $arousal
            (clamp01 (- $approach (* 0.5 $bump)))
            $resolution
            (clamp01 (+ $threshold $bump))
            (clamp01 (+ $securing $bump))))))))
