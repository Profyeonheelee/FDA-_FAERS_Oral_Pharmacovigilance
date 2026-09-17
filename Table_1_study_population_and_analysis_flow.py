#!/usr/bin/env python3
"""Generate Table 1: FAERS dataset and sequential analytic selection."""

from _publication_common import (
    DATA_ROOT,
    load_final_adjudication,
    load_primary,
    load_sensitivity,
    read_csv,
    write_csv,
)
import pandas as pd


robust, persistent = load_primary()
sensitivity_robust, _ = load_sensitivity()
adjudication = load_final_adjudication()
primary_summary_data = read_csv(
    DATA_ROOT / "03_signal_analysis_primary/step6_primary_analysis_summary.csv"
)
primary_summary = dict(zip(primary_summary_data["metric"], primary_summary_data["value"]))
ps_counts = read_csv(
    DATA_ROOT / "02_faers_aggregates/faers_v2_1_PS_counts_by_ingredient.csv"
)

rows = [
    ("Study period", "2004 Q1–2026 Q2"),
    ("Quarterly FAERS extracts", 90),
    ("Deduplicated, non-deleted reports", 20616119),
    ("Canonical pharmacovigilance ingredients", 1647),
    ("Ingredients with ≥1 true primary-suspect report", len(ps_counts)),
    ("Primary drug universe, true PS ≥500", int(primary_summary["Primary drugs with true PS >=500"])),
    ("Sensitivity drug universe, true PS ≥100", 1390),
    ("Locked oral MedDRA Preferred Terms", 72),
    ("Primary inferential oral Preferred Terms", 25),
    ("Primary drug–PT pairs tested", 27975),
    ("Drug–PT pairs with ≥10 co-reports", 3803),
    ("Robust disproportionality signals", len(robust)),
    ("Robust and temporally repeated PT-level signals", len(persistent)),
    ("Unique drugs represented among persistent robust signals", persistent["canonical_pharmacovigilance_ingredient"].nunique()),
    ("Drug–clinical concept units evaluated against FDA labeling", len(adjudication)),
]

table = pd.DataFrame(rows, columns=["Characteristic", "Value"])
write_csv(table, "table1_study_population_and_analysis_flow.csv")
write_csv(table.copy(), "figure0_flow_data.csv")
