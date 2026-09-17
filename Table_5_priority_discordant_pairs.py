#!/usr/bin/env python3
"""Generate Table 5: selected high-strength persistent discordant pairs."""

import pandas as pd

from _publication_common import DOMAIN_ORDER, load_final_adjudication, load_primary, write_csv


_, signals = load_primary()
adjudication = load_final_adjudication()
discordant = adjudication[adjudication["final_label_status"] == "Not identified"].copy()

lead = (
    signals.sort_values("EB05", ascending=False)
    .drop_duplicates(["canonical_pharmacovigilance_ingredient", "Clinical_concept"])
)
eligible = discordant.merge(
    lead,
    on=["canonical_pharmacovigilance_ingredient", "Clinical_concept", "Domain"],
    how="inner",
    suffixes=("_unit", ""),
)
eligible = eligible[eligible["a_co_reports"] >= 20].copy()

# Fluconazole–oral candidiasis was not prioritized because the matched label
# wording occurs in indication and dosing context rather than as a safety event.
exclude = (
    (eligible["canonical_pharmacovigilance_ingredient"] == "FLUCONAZOLE")
    & (eligible["Clinical_concept"] == "Oral candidiasis")
)
eligible = eligible[~exclude]
eligible["Domain"] = pd.Categorical(eligible["Domain"], DOMAIN_ORDER, ordered=True)
selected = (
    eligible.sort_values(["Domain", "EB05"], ascending=[True, False])
    .groupby("Domain", observed=True, sort=False)
    .head(2)
    .sort_values(["Domain", "EB05"], ascending=[True, False])
)

columns = [
    "Domain",
    "canonical_pharmacovigilance_ingredient",
    "Clinical_concept",
    "MedDRA_PT",
    "a_co_reports",
    "ROR",
    "ROR_lower95",
    "ROR_upper95",
    "PRR",
    "IC025",
    "EBGM",
    "EB05",
    "BH_FDR_q",
    "distinct_reporting_years",
    "first_reporting_year",
    "last_reporting_year",
    "brand_names",
]
table = selected[columns].copy()
table["Selection_rule"] = (
    "Up to two highest-EB05 Not identified persistent robust pairs per domain "
    "with lead PT a≥20, excluding direct indication or dosing-context overlap"
)
if len(table) != 14:
    raise ValueError(f"Expected 14 priority pairs; found {len(table)}")
write_csv(table, "table5_priority_signal_label_discordant_pairs.csv")
write_csv(table.assign(plot_label=table["canonical_pharmacovigilance_ingredient"].str.title() + " – " + table["Clinical_concept"]), "figure4_priority_forest_data.csv")
