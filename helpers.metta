; helpers.metta
; Small general-purpose utilities used by the rest of the project.
; All arithmetic in PeTTa is strictly binary, so sums are nested.

; Modulators and overgoals must always stay in [0,1]; every update
; passes through this so nothing can drift out of range.
(= (clamp01 $x)
   (if (< $x 0.0)
       0.0
       (if (> $x 1.0) 1.0 $x)))

; Used by the decision step to pick the best-scoring action.
(= (max2 $a $b) (if (> $a $b) $a $b))

; new = (1 - alpha) * old + alpha * target      (paper 2's update rule)
(= (blend2 $old $target $alpha)
   (+ (* (- 1.0 $alpha) $old) (* $alpha $target)))
