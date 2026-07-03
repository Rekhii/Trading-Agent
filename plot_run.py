#!/usr/bin/env python3
# =====================================================================
# plot_run.py
# ---------------------------------------------------------------------
# Turns the trading run log (BOTH series) into paper-style trajectory
# figures, in the spirit of Figures 1 and 2 of the second MetaMo paper.
#
# Usage:
#   1. Capture the log (strips PeTTa's color codes):
#        sh ~/PeTTa/run.sh main.metta 2>/dev/null | \
#          sed 's/\x1b\[[0-9;]*m//g' | \
#          grep -aE "^\((BASELINE|METAMO|=== SERIES)" > run_log.txt
#   2. Make the figures:
#        python3 plot_run.py run_log.txt
#
# Produces four PNGs:
#   fig1_seriesA_price_value.png : series A - price + both values
#   fig2_overgoals.png           : series A - gInd / gTrans over time
#   fig3_emotions_actions.png    : series A - emotion+action timeline
#   fig4_two_markets.png         : A vs B - the stability comparison
# =====================================================================

import re
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

# ----- 1. read the log and split it into the four runs ------------------
# The log contains, in order:
#   baseline run A, metamo run A, "=== SERIES B" header,
#   baseline run B, metamo run B.
# A step 1 line starts a new run; the SERIES B header flips series.

logfile = sys.argv[1] if len(sys.argv) > 1 else "run_log.txt"
ansi = re.compile(r"\x1b\[[0-9;]*m")
lines = [ansi.sub("", line).strip() for line in open(logfile)]

base_re = re.compile(
    r"\(BASELINE step (\d+) price ([\d.]+) action (\w+) value ([\d.]+)\)")
meta_re = re.compile(
    r"\(METAMO step (\d+) price ([\d.]+) emotion (\w+) face \S+ "
    r"gInd ([\d.]+) gTrans ([\d.]+) action (\w+) value ([\d.]+)\)")

def new_run():
    return {"step": [], "price": [], "emotion": [], "gInd": [],
            "gTrans": [], "action": [], "value": []}

runs = {"A": {"base": new_run(), "meta": new_run()},
        "B": {"base": new_run(), "meta": new_run()}}
series = "A"

for line in lines:
    if "SERIES B" in line:
        series = "B"
        continue
    m = base_re.match(line)
    if m:
        r = runs[series]["base"]
        r["step"].append(int(m.group(1)))
        r["price"].append(float(m.group(2)))
        r["action"].append(m.group(3))
        r["value"].append(float(m.group(4)))
        continue
    m = meta_re.match(line)
    if m:
        r = runs[series]["meta"]
        r["step"].append(int(m.group(1)))
        r["price"].append(float(m.group(2)))
        r["emotion"].append(m.group(3))
        r["gInd"].append(float(m.group(4)))
        r["gTrans"].append(float(m.group(5)))
        r["action"].append(m.group(6))
        r["value"].append(float(m.group(7)))

if not runs["A"]["meta"]["step"]:
    sys.exit("No METAMO lines found - check the capture command.")

EMO_COLOR = {"Fear": "tab:red", "Confident": "tab:green",
             "Sad": "tab:purple", "Neutral": "tab:gray"}
ACT_MARK = {"Buy": "^", "Sell": "v", "Hold": "o"}

baseline_a, metamo_a = runs["A"]["base"], runs["A"]["meta"]
baseline_b, metamo_b = runs["B"]["base"], runs["B"]["meta"]

# ----- 2. figure 1: series A price and portfolio values ------------------

fig, ax1 = plt.subplots(figsize=(9, 4.5))
ax1.plot(metamo_a["step"], metamo_a["price"], "k--", label="Price", lw=1.2)
ax1.set_xlabel("Step"); ax1.set_ylabel("Price")
ax2 = ax1.twinx()
ax2.plot(baseline_a["step"], baseline_a["value"], color="tab:orange",
         label="Baseline value", lw=1.8)
ax2.plot(metamo_a["step"], metamo_a["value"], color="tab:blue",
         label="MetaMo value", lw=1.8)
ax2.set_ylabel("Portfolio value")
handles_price, labels_price = ax1.get_legend_handles_labels()
handles_value, labels_value = ax2.get_legend_handles_labels()
ax1.legend(handles_price + handles_value, labels_price + labels_value, loc="lower left")
plt.title("Series A: price and portfolio value, baseline vs MetaMo")
plt.tight_layout(); plt.savefig("fig1_seriesA_price_value.png", dpi=150)
plt.close()

# ----- 3. figure 2: series A overgoals -----------------------------------

plt.figure(figsize=(9, 4))
plt.plot(metamo_a["step"], metamo_a["gInd"], color="tab:red", lw=1.8,
         label="g_Ind (individuation / protect capital)")
plt.plot(metamo_a["step"], metamo_a["gTrans"], color="tab:green", lw=1.8,
         label="g_Trans (transcendence / chase gains)")
plt.xlabel("Step"); plt.ylabel("Overgoal intensity"); plt.ylim(0, 1)
plt.legend(loc="best")
plt.title("Series A: MetaMo overgoals over the run")
plt.tight_layout(); plt.savefig("fig2_overgoals.png", dpi=150)
plt.close()

# ----- 4. figure 3: series A emotion + action timeline -------------------

fig, (ax_metamo, ax_baseline) = plt.subplots(2, 1, figsize=(9, 4.5), sharex=True)
for s, e, a, p in zip(metamo_a["step"], metamo_a["emotion"],
                      metamo_a["action"], metamo_a["price"]):
    ax_metamo.scatter(s, p, color=EMO_COLOR.get(e, "tab:gray"),
                marker=ACT_MARK.get(a, "o"), s=110, zorder=3)
ax_metamo.plot(metamo_a["step"], metamo_a["price"], color="lightgray", zorder=1)
ax_metamo.set_ylabel("Price")
ax_metamo.set_title("MetaMo: emotion (color) and action (marker) on the price path")
for s, a, p in zip(baseline_a["step"], baseline_a["action"], baseline_a["price"]):
    ax_baseline.scatter(s, p, color="tab:orange",
                marker=ACT_MARK.get(a, "o"), s=110, zorder=3)
ax_baseline.plot(baseline_a["step"], baseline_a["price"], color="lightgray", zorder=1)
ax_baseline.set_ylabel("Price"); ax_baseline.set_xlabel("Step")
ax_baseline.set_title("Baseline: same rule forever (no emotions)")
legend_items = (
    [Line2D([], [], color=c, marker="s", ls="", label=e)
     for e, c in EMO_COLOR.items()] +
    [Line2D([], [], color="black", marker=m, ls="", label=a)
     for a, m in ACT_MARK.items()])
ax_metamo.legend(handles=legend_items, loc="lower left", ncol=4, fontsize=8)
plt.tight_layout(); plt.savefig("fig3_emotions_actions.png", dpi=150)
plt.close()

# ----- 5. figure 4: the two-market stability comparison ------------------
# Left: series A (real recovery). Right: series B (fake recovery).
# Same agents, same rules; only the market differs. The MetaMo agent
# ends at the same value on both - the baseline swings with luck.

fig, (axA, axB) = plt.subplots(1, 2, figsize=(11, 4.2), sharey=True)
for ax, base, meta, title in (
        (axA, baseline_a, metamo_a, "Series A: recovery is real"),
        (axB, baseline_b, metamo_b, "Series B: recovery is a trap")):
    ax.plot(base["step"], base["value"], color="tab:orange",
            lw=1.8, label="Baseline value")
    ax.plot(meta["step"], meta["value"], color="tab:blue",
            lw=1.8, label="MetaMo value")
    ax.annotate(f'{base["value"][-1]:.1f}',
                (base["step"][-1], base["value"][-1]),
                color="tab:orange", fontweight="bold",
                textcoords="offset points", xytext=(6, -4))
    ax.annotate(f'{meta["value"][-1]:.1f}',
                (meta["step"][-1], meta["value"][-1]),
                color="tab:blue", fontweight="bold",
                textcoords="offset points", xytext=(6, 4))
    ax.set_xlabel("Step"); ax.set_title(title)
axA.set_ylabel("Portfolio value")
axA.legend(loc="lower left")
plt.suptitle("Same agents, two markets: MetaMo's outcome is stable, "
             "the baseline's depends on luck")
plt.tight_layout(); plt.savefig("fig4_two_markets.png", dpi=150)
plt.close()


# Figure 5: the batch experiment. One dot per random market, baseline
# final value on the x axis, MetaMo final value on the y axis. Dots
# above the diagonal are markets where MetaMo ended higher. The
# dashed lines mark each agent's worst case across all markets.

batch_re = re.compile(
    r"\(BATCHRUN seed \d+ baseline ([\d.]+) metamo ([\d.]+)\)")
baseline_values, metamo_values = [], []
for line in lines:
    m = batch_re.match(line)
    if m:
        baseline_values.append(float(m.group(1)))
        metamo_values.append(float(m.group(2)))

if baseline_values:
    plt.figure(figsize=(6.5, 6))
    lo = min(min(baseline_values), min(metamo_values)) - 3
    hi = max(max(baseline_values), max(metamo_values)) + 3
    plt.plot([lo, hi], [lo, hi], color="gray", ls="--", lw=1,
             label="Equal outcome")
    plt.scatter(baseline_values, metamo_values, color="tab:blue", s=45, zorder=3)
    plt.axvline(min(baseline_values), color="tab:orange", ls=":", lw=1.5,
                label=f"Baseline worst {min(baseline_values):.1f}")
    plt.axhline(min(metamo_values), color="tab:blue", ls=":", lw=1.5,
                label=f"MetaMo worst {min(metamo_values):.1f}")
    plt.xlabel("Baseline final value")
    plt.ylabel("MetaMo final value")
    plt.title(f"{len(baseline_values)} random markets: one dot per market\n"
              "above the diagonal = MetaMo ended higher")
    plt.legend(loc="upper left", fontsize=9)
    plt.tight_layout()
    plt.savefig("fig5_batch.png", dpi=150)
    plt.close()



# Figure 6: how the emotional state drives decisions away from the
# baseline, on series B. Top: the price path with both agents'
# actions; steps where the two agents chose differently are shaded.
# Bottom: the caution drive gInd over the same steps. The shaded
# divergences line up with elevated caution: the agent refuses the
# fake bounce because it is still shaken, and that refusal is the
# entire profit difference.

if metamo_b["step"]:
    fig, (ax_price, ax_caution) = plt.subplots(2, 1, figsize=(9.5, 6), sharex=True,
                                   gridspec_kw={"height_ratios": [2, 1]})
    diverge = [s for s, bm, mm in zip(metamo_b["step"], baseline_b["action"],
                                      metamo_b["action"]) if bm != mm]
    for s in diverge:
        for ax in (ax_price, ax_caution):
            ax.axvspan(s - 0.5, s + 0.5, color="gold", alpha=0.25, zorder=0)

    ax_price.plot(metamo_b["step"], metamo_b["price"], color="lightgray", zorder=1)
    for s, e, a, p in zip(metamo_b["step"], metamo_b["emotion"],
                          metamo_b["action"], metamo_b["price"]):
        ax_price.scatter(s, p, color=EMO_COLOR.get(e, "tab:gray"),
                    marker=ACT_MARK.get(a, "o"), s=120, zorder=3)
    for s, a, p in zip(baseline_b["step"], baseline_b["action"], baseline_b["price"]):
        ax_price.scatter(s, p - 0.55, color="tab:orange",
                    marker=ACT_MARK.get(a, "o"), s=55, zorder=2)
    ax_price.set_ylabel("Price")
    ax_price.set_title("Series B: MetaMo actions (big, emotion-colored) vs "
                  "baseline actions (small orange)\n"
                  "gold bands = the two agents disagree")
    legend_items = (
        [Line2D([], [], color=c, marker="s", ls="", label=e)
         for e, c in EMO_COLOR.items()] +
        [Line2D([], [], color="black", marker=m, ls="", label=a)
         for a, m in ACT_MARK.items()])
    ax_price.legend(handles=legend_items, loc="upper right", ncol=2, fontsize=8)

    ax_caution.plot(metamo_b["step"], metamo_b["gInd"], color="tab:red", lw=2,
             label="g_Ind (caution drive)")
    ax_caution.axhline(0.5, color="gray", ls="--", lw=1, label="neutral")
    ax_caution.set_ylabel("g_Ind")
    ax_caution.set_xlabel("Step")
    ax_caution.set_ylim(0.35, 0.7)
    ax_caution.legend(loc="lower right", fontsize=9)
    ax_caution.annotate("caution still elevated:\nagent refuses the bounce",
                 xy=(10.5, 0.60), xytext=(6.2, 0.63), fontsize=9,
                 arrowprops=dict(arrowstyle="->", color="black", lw=1))
    plt.tight_layout()
    plt.savefig("fig6_emotion_decision.png", dpi=150)
    plt.close()

print("Wrote fig1_seriesA_price_value.png, fig2_overgoals.png,")
print("fig3_emotions_actions.png, fig4_two_markets.png,")
print("fig5_batch.png, fig6_emotion_decision.png")
