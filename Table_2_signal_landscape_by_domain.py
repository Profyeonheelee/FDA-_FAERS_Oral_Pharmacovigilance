#!/usr/bin/env python3
"""Generate Table 2: persistent robust signals by oral adverse-event domain."""

import pandas as pd

from _publication_common import DOMAIN_ORDER, PRIMARY_DIR, load_primary, read_csv, write_csv


robust, persistent = load_primary()
domain_source = read_csv(PRIMARY_DIR / "step6_primary_domain_summary.csv").set_index("Domain")
primary_pts = persistent.groupby("Domain")["MedDRA_PT"].nunique().to_dict()
primary_pts.update({"Salivary dysfunction": 4, "Oral mucosal / tongue": 6, "Taste / chemosensory": 4, "Jaw / alveolar bone": 1, "Oral infection": 1, "Dental / pulpal": 5, "Gingival / periodontal": 4})

rows = []
for domain in DOMAIN_ORDER:
    signals = persistent[persistent["Domain"] == domain]
    source = domain_source.loc[domain]
    rows.append({
        "Domain": domain,
        "Primary_PTs": primary_pts[domain],
        "Tested_pairs": int(source["tested_pairs"]),
        "a_ge_10_pairs": int(source["a_ge_10_pairs"]),
        "Robust_signals": int(source["robust_signals"]),
        "Persistent_robust_signals": len(signals),
        "Persistent_signal_yield_pct_of_a_ge_10": 100 * len(signals) / source["a_ge_10_pairs"],
        "Unique_drugs_in_persistent_signals": signals["canonical_pharmacovigilance_ingredient"].nunique(),
        "Median_a": signals["a_co_reports"].median(),
        "IQR_a_low": signals["a_co_reports"].quantile(0.25),
        "IQR_a_high": signals["a_co_reports"].quantile(0.75),
        "Median_ROR": signals["ROR"].median(),
        "IQR_ROR_low": signals["ROR"].quantile(0.25),
        "IQR_ROR_high": signals["ROR"].quantile(0.75),
        "Median_EB05": signals["EB05"].median(),
        "IQR_EB05_low": signals["EB05"].quantile(0.25),
        "IQR_EB05_high": signals["EB05"].quantile(0.75),
    })

write_csv(pd.DataFrame(rows), "table2_signal_landscape_by_domain.csv")
