#!/usr/bin/env python3
"""Generate Supplementary Table S2: domain-level signal characteristics."""

import pandas as pd

from _publication_common import DOMAIN_ORDER, PRIMARY_DIR, load_primary, read_csv, write_csv


robust, persistent = load_primary()
domain_source = read_csv(PRIMARY_DIR / "step6_primary_domain_summary.csv").set_index("Domain")
pt_counts = {"Salivary dysfunction": 4, "Oral mucosal / tongue": 6, "Taste / chemosensory": 4, "Jaw / alveolar bone": 1, "Oral infection": 1, "Dental / pulpal": 5, "Gingival / periodontal": 4}

panel_a = []
panel_b = []
for domain in DOMAIN_ORDER + ["Overall"]:
    if domain == "Overall":
        tested, eligible = 27975, 3803
        domain_robust, domain_persistent = robust, persistent
        primary_pts = 25
    else:
        source = domain_source.loc[domain]
        tested, eligible = int(source["tested_pairs"]), int(source["a_ge_10_pairs"])
        domain_robust = robust[robust["Domain"] == domain]
        domain_persistent = persistent[persistent["Domain"] == domain]
        primary_pts = pt_counts[domain]
    panel_a.append({
        "Domain": domain,
        "Primary_PTs": primary_pts,
        "Tested_pairs": tested,
        "a_ge_10_pairs": eligible,
        "Robust_signals": len(domain_robust),
        "Persistent_robust_signals": len(domain_persistent),
        "Persistent_signal_yield_pct": 100 * len(domain_persistent) / eligible,
        "Unique_drugs": domain_persistent["canonical_pharmacovigilance_ingredient"].nunique(),
    })
    row = {"Domain": domain}
    for variable, prefix in [("a_co_reports", "a"), ("ROR", "ROR"), ("EB05", "EB05")]:
        row[f"Median_{prefix}"] = domain_persistent[variable].median()
        row[f"Q1_{prefix}"] = domain_persistent[variable].quantile(0.25)
        row[f"Q3_{prefix}"] = domain_persistent[variable].quantile(0.75)
    panel_b.append(row)

write_csv(pd.DataFrame(panel_a), "supplementary_table_S2_panel_A_signal_counts.csv")
write_csv(pd.DataFrame(panel_b), "supplementary_table_S2_panel_B_signal_strength.csv")
