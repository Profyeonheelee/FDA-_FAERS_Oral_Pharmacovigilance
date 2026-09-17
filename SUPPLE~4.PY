#!/usr/bin/env python3
"""Generate Supplementary Table S6: characteristics of discordant review units."""

import pandas as pd

from _publication_common import CONCEPT_ORDER, DOMAIN_ORDER, load_final_adjudication, write_csv


data = load_final_adjudication()
data["reporting_duration_years"] = data["latest_signal_year"] - data["earliest_signal_year"] + 1
discordant = data[data["final_label_status"] == "Not identified"].copy()

def summary_row(subset: pd.DataFrame) -> dict[str, float]:
    result = {"Unique_drugs_with_discordant_units": subset["canonical_pharmacovigilance_ingredient"].nunique()}
    for variable, prefix in [("max_EB05", "Max_EB05"), ("max_ROR", "Max_ROR"), ("reporting_duration_years", "Reporting_duration_years")]:
        result[f"{prefix}_median"] = subset[variable].median()
        result[f"{prefix}_Q1"] = subset[variable].quantile(0.25)
        result[f"{prefix}_Q3"] = subset[variable].quantile(0.75)
    return result

panel_a = []
for domain in DOMAIN_ORDER + ["Overall"]:
    all_units = data if domain == "Overall" else data[data["Domain"] == domain]
    subset = discordant if domain == "Overall" else discordant[discordant["Domain"] == domain]
    row = {
        "Domain": domain,
        "Review_units": len(all_units),
        "Not_identified_n": len(subset),
        "Not_identified_pct": 100 * len(subset) / len(all_units),
    }
    row.update(summary_row(subset))
    panel_a.append(row)

panel_b = []
for domain in DOMAIN_ORDER:
    domain_all = data[data["Domain"] == domain]
    concepts = [c for c in CONCEPT_ORDER if c in set(domain_all["Clinical_concept"])]
    for concept in concepts:
        all_units = domain_all[domain_all["Clinical_concept"] == concept]
        subset = discordant[(discordant["Domain"] == domain) & (discordant["Clinical_concept"] == concept)]
        row = {
            "Domain": domain,
            "Clinical_concept": concept,
            "Review_units": len(all_units),
            "Not_identified_n": len(subset),
            "Not_identified_pct": 100 * len(subset) / len(all_units),
        }
        row.update(summary_row(subset))
        panel_b.append(row)

write_csv(pd.DataFrame(panel_a), "supplementary_table_S6_panel_A_domain_characteristics.csv")
write_csv(pd.DataFrame(panel_b), "supplementary_table_S6_panel_B_concept_characteristics.csv")
