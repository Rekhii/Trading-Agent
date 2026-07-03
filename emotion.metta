; emotion.metta
; Turns the modulator vector into a readable emotion label each step.
;
; NOTE: this is a simple threshold stand-in with the same interface as
; the fuzzy emotion formulas I implemented and merged in the earlier
; MetaMo task (which map modulators -> happy/sad/angry/fear). When this
; runs inside the real MetaMo repo, this file is replaced by a call to
; that merged emotion code; the rest of the project does not change.
;
; The mapping follows the same qualitative logic as OpenPsi:
;   Fear      : cautious + on edge      (securing high AND threshold high)
;   Confident : feeling good + engaged  (valence high AND approach high)
;   Sad       : feeling bad + withdrawn (valence low  AND approach low)
;   Neutral   : anything in between

; (emotionOf $modulators) -> Fear | Confident | Sad | Neutral
(= (emotionOf $modulators)
   (let ($valence $arousal $approach $resolution $threshold $securing) $modulators
     (if (and (> $securing 0.60) (> $threshold 0.60))
         Fear
         (if (and (> $valence 0.6) (> $approach 0.6))
             Confident
             (if (and (< $valence 0.4) (< $approach 0.45))
                 Sad
                 Neutral)))))

; Makes the emotion readable at a glance in the step log.
(= (moodFace Fear)      (o_o))
(= (moodFace Confident) (n_n))
(= (moodFace Sad)       (u_u))
(= (moodFace Neutral)   (-_-))
