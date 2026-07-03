; Batch experiment over random markets
; Runs both agents over many randomly generated price series and
; reports the distribution of final values (worst, mean, best).
; This turns the two hand-made series into a statistical comparison:
; the claim is not that MetaMo earns more, but that its outcomes are
; more stable, with a better worst case, across markets it has never
; been tuned on.

; A small linear congruential generator so the random walks are
; reproducible without any library dependency. Same seed, same
; markets, same results, every run.
(= (lcg $seed) (% (+ (* 1103515245 $seed) 12345) 2147483648))

; Map a seed to one price step. Four moves, net drift zero, so the
; generated markets are fair to both agents. The seed is first passed
; through an odd prime modulus because the low bits of an LCG cycle
; with a short period; without this every market has the same shape.
(= (stepOf $seed)
   (let $choice (% (% $seed 9973) 4)
     (if (== $choice 0) -1.2
     (if (== $choice 1) -0.5
     (if (== $choice 2)  0.5
                    1.2)))))

; Generate a random price series of length $n starting at $price.
; Prices are floored at 2.0 so a long losing streak cannot go negative.
(= (genSeries $n $seed $price)
   (if (== $n 0)
       ()
       (let* (($newSeed (lcg $seed))
              ($nextPrice  (+ $price (stepOf $newSeed)))
              ($safePrice  (if (< $nextPrice 2.0) 2.0 $nextPrice)))
         (cons-atom $price (genSeries (- $n 1) $newSeed $safePrice)))))

; Run both agents over $runsLeft random markets and fold the results into
; running stats, carried as (min mean-sum max) per agent. Recursion
; keeps everything pure; no atomspace mutation needed.
(= (batchLoop $runsLeft $seed $baselineWorst $baselineSum $baselineBest $metamoWorst $metamoSum $metamoBest)
   (if (== $runsLeft 0)
       ((BASELINE worst $baselineWorst mean (/ $baselineSum (BATCH_RUNS)) best $baselineBest)
        (METAMO   worst $metamoWorst mean (/ $metamoSum (BATCH_RUNS)) best $metamoBest))
       (let* (($newSeed  (lcg (* $seed 7)))
              ($priceSeries (genSeries (BATCH_LEN) $newSeed 10.0))
              ($baselineValue     (baselineRunQ $priceSeries 10.0 (INITIAL_CASH) 0))
              ($metamoValue     (metamoRunQ $priceSeries 10.0 (INITIAL_CASH) 0 (INITIAL_MODS) 0.5 0.5 (INITIAL_CASH)))
              ($_      (println! (BATCHRUN seed $newSeed baseline $baselineValue metamo $metamoValue))))
         (batchLoop (- $runsLeft 1) $newSeed
                    (if (< $baselineValue $baselineWorst) $baselineValue $baselineWorst) (+ $baselineSum $baselineValue) (if (> $baselineValue $baselineBest) $baselineValue $baselineBest)
                    (if (< $metamoValue $metamoWorst) $metamoValue $metamoWorst) (+ $metamoSum $metamoValue) (if (> $metamoValue $metamoBest) $metamoValue $metamoBest)))))

; Entry point: run the batch from a fixed seed and print the summary.
(= (runBatch)
   (batchLoop (BATCH_RUNS) 42 999999.0 0.0 -999999.0 999999.0 0.0 -999999.0))
