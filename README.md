# Emotionally-Modulated Trading Agent (MetaMo Use Case)

A trading agent whose decisions are driven by an emotional and motivational
system, implemented in MeTTa and run through PeTTa. Built as a use case for
the MetaMo framework during my iCog Labs internship, based on the papers
"MetaMo: A Robust Motivational Framework for Open-Ended AGI" and
"From MetaMo to Open-Ended OpenPsi" (Goertzel and Lian).

The agent trades a single asset over a price series, choosing buy, hold, or
sell each step. Its behavior is shaped by:

- **Six OpenPsi modulators** (valence, arousal, approach, resolution,
  threshold, securing), updated each step by an appraisal of what the
  market just did
- **Two overgoals**: individuation (protect capital) and transcendence
  (chase gains), implemented as real state with tracking, cooling, and a
  slowly adapting reference point (habituation), so caution rises after
  losses and fades with time instead of freezing
- **The MetaMo cycle** F = D o Psi: appraise, blend the state gradually,
  score every action, act
- **Emergent emotions** (fear, confident, sad, neutral) computed from the
  modulators as readouts. They label the state that drives behavior; they
  are not hard-coded rules, matching the OpenPsi position

A fixed-rule momentum **baseline** (buy after a rise, sell after a fall, no
internal state) trades under identical market rules, so any behavioral
difference is attributable to the MetaMo machinery.

## Results in one paragraph

On a market whose crash genuinely recovers, the reckless baseline finishes
ahead (96.5 vs 93.5). On the same market where the recovery is a trap, the
MetaMo agent finishes ahead (93.5 vs 89.5) because its lingering caution
refuses the fake bounce. Over 30 random markets neither agent was tuned on,
the MetaMo agent ends higher on 24, its worst case is 93.4 vs the
baseline's 88.3, and it matches the baseline on the strongest bull runs.
The claim is not that the emotional agent earns more; it is that its
outcomes are stable while the baseline's depend on market luck. This is the
papers' homeostatic stability principle showing up as money.

## Project structure

| File | What it does |
| --- | --- |
| `main.metta` | Entry point: runs both agents on series A and B, then the batch experiment |
| `config.metta` | All constants: price series, appraisal step sizes, overgoal dynamics, scoring weights, batch settings |
| `helpers.metta` | clamp01, max2, and the incremental blend |
| `baseline.metta` | The fixed-rule baseline, plus the shared market rules (execAction, portfolioValue) used by both agents |
| `appraisal.metta` | The Psi step: modulator updates, overgoal targets, tracking/cooling dynamics, habituation reference |
| `emotion.metta` | Modulators to emotion label (threshold stand-in with the same interface as the merged MetaMo emotion formulas) |
| `decision.metta` | The D step: the paper's scoring equation (Section 5.1 form), corr/risk/bold per action, argmax |
| `agent.metta` | The full MetaMo step and run loops (verbose and quiet) |
| `batch.metta` | Reproducible random-market generator (seeded LCG) and the 30-market batch experiment |
| `plot_run.py` | Parses the run log and produces the six figures |
| `fig1..fig6 *.png` | Sample figures from a verified run |

## Requirements

- SWI-Prolog
- [PeTTa](https://github.com/trueagi-io/PeTTa) cloned at `~/PeTTa`
- Python 3 with matplotlib (only for the figures)

## How to run

From the project folder:

```bash
# 1. Run the simulation and save a clean log
sh ~/PeTTa/run.sh main.metta 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "^\((BASELINE|METAMO|BATCHRUN|===)" > run_log.txt

# 2. Generate the six figures
python3 plot_run.py run_log.txt
```

Expected final values in the log:

```
(BASELINE_FINAL_VALUE 96.5)     series A, recovery is real
(METAMO_FINAL_VALUE 93.5)
(BASELINE_B_FINAL_VALUE 89.5)   series B, recovery is a trap
(METAMO_B_FINAL_VALUE 93.5)
(BATCH_SUMMARY ...)             30 random markets: worst/mean/best per agent
```

The batch uses a fixed seed, so results are fully reproducible.

## The figures

- `fig1` series A: price and both portfolio values; the curves split after the crash bottom
- `fig2` series A: the two overgoals over time; the crossover is the agent's stance flipping
- `fig3` series A: emotion (color) and action (marker) per step; fear fires at the crash bottom
- `fig4` both series side by side: MetaMo ends at 93.5 in both worlds, the baseline swings 96.5 to 89.5
- `fig5` the batch: one dot per random market; most sit above the equal-outcome diagonal, and the worst-case lines show MetaMo's floor above the baseline's
- `fig6` series B: where the two agents disagree (shaded) lined up against the caution drive that causes it

## Notes

- The emotion labels are causally inert by design: deleting `emotion.metta`
  changes only the logs. The modulators and overgoals the emotions describe
  do the causal work, per OpenPsi.
- Series B is deliberately constructed to punish blind re-buying; its value
  is only in contrast with series A. The batch experiment carries the
  statistical weight.
- Constants are hand-tuned on series A/B and fixed before the batch ran; a
  sensitivity sweep is the natural next step.
- corr/risk/bold per action are my design; the papers give the scoring form
  but leave these to the implementer.
