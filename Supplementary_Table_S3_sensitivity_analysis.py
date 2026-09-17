#!/usr/bin/env python3
"""Generate Supplementary Table S3: expanded-universe sensitivity analysis."""

import pandas as pd

from _publication_common import DOMAIN_ORDER, load_primary, load_sensitivity, signal_keys, write_csv


primary_robust, primary_persistent = load_primary()
sensitivity_robust, sensitivity_persistent = load_sensitivity()

panel_a = pd.DataFrame([
    ("Drug universe, true PS threshold", "≥500 reports", "≥100 reports"),
    ("Number of drugs", 1119, 1390),
    ("Primary oral MedDRA PTs", 25, 25),
    ("Tested drug–PT pairs", 27975, 34750),
    ("Co-report eligibility threshold", "a ≥10", "a ≥5"),
    ("Eligible drug–PT pairs", 3803, 5715),
    ("Robust signals", 791, 890),
    ("Robust + temporally repeated signals", 750, 767),
    ("Primary robust signals recovered", "Reference", "791 / 791 (100.0%)"),
    ("Primary persistent robust signals recovered", "Reference", "750 / 750 (100.0%)"),
    ("Additional sensitivity-only robust signals", "—", 99),
    ("Additional sensitivity-only persistent robust signals", "—", 17),
], columns=["Characteristic", "Primary_analysis", "Sensitivity_analysis"])

rows = []
for domain in DOMAIN_ORDER + ["Overall"]:
    pr = primary_robust if domain == "Overall" else primary_robust[primary_robust["Domain"] == domain]
    sr = sensitivity_robust if domain == "Overall" else sensitivity_robust[sensitivity_robust["Domain"] == domain]
    pp = primary_persistent if domain == "Overall" else primary_persistent[primary_persistent["Domain"] == domain]
    sp = sensitivity_persistent if domain == "Overall" else sensitivity_persistent[sensitivity_persistent["Domain"] == domain]
    pr_keys, sr_keys = signal_keys(pr), signal_keys(sr)
    pp_keys, sp_keys = signal_keys(pp), signal_keys(sp)
    rows.append({
        "Domain": domain,
        "Primary_robust": len(pr_keys),
        "Sensitivity_robust": len(sr_keys),
        "Recovered_primary_robust_n": len(pr_keys & sr_keys),
        "Recovered_primary_robust_pct": 100 * len(pr_keys & sr_keys) / len(pr_keys),
        "Sensitivity_only_robust": len(sr_keys - pr_keys),
        "Primary_persistent": len(pp_keys),
        "Sensitivity_persistent": len(sp_keys),
        "Recovered_primary_persistent_n": len(pp_keys & sp_keys),
        "Recovered_primary_persistent_pct": 100 * len(pp_keys & sp_keys) / len(pp_keys),
        "Sensitivity_only_persistent": len(sp_keys - pp_keys),
    })

write_csv(panel_a, "supplementary_table_S3_panel_A_overall_sensitivity.csv")
write_csv(pd.DataFrame(rows), "supplementary_table_S3_panel_B_domain_recovery.csv")
