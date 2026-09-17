#!/usr/bin/env python3
"""Generate Supplementary Table S7: clinical-concept-level label concordance."""

import pandas as pd

from _publication_common import CONCEPT_ORDER, DOMAIN_ORDER, load_final_adjudication, write_csv


data = load_final_adjudication()
rows = []
for domain in DOMAIN_ORDER:
    domain_data = data[data["Domain"] == domain]
    concepts = [c for c in CONCEPT_ORDER if c in set(domain_data["Clinical_concept"])]
    for concept in concepts:
        subset = domain_data[domain_data["Clinical_concept"] == concept]
        n = len(subset)
        explicit = int((subset["final_label_status"] == "Explicitly represented").sum())
        broad = int((subset["final_label_status"] == "Broadly represented").sum())
        not_identified = int((subset["final_label_status"] == "Not identified").sum())
        rows.append({
            "Domain": domain,
            "Clinical_concept": concept,
            "Review_units": n,
            "Explicitly_represented_n": explicit,
            "Explicitly_represented_pct": 100 * explicit / n,
            "Broadly_represented_n": broad,
            "Broadly_represented_pct": 100 * broad / n,
            "Represented_total_n": explicit + broad,
            "Represented_total_pct": 100 * (explicit + broad) / n,
            "Not_identified_n": not_identified,
            "Not_identified_pct": 100 * not_identified / n,
        })

table = pd.DataFrame(rows)
overall = pd.DataFrame([{
    "Domain": "Overall",
    "Clinical_concept": "All clinical concepts",
    "Review_units": len(data),
    "Explicitly_represented_n": int((data["final_label_status"] == "Explicitly represented").sum()),
    "Explicitly_represented_pct": 50.0,
    "Broadly_represented_n": int((data["final_label_status"] == "Broadly represented").sum()),
    "Broadly_represented_pct": 100 * 41 / 726,
    "Represented_total_n": 404,
    "Represented_total_pct": 100 * 404 / 726,
    "Not_identified_n": 322,
    "Not_identified_pct": 100 * 322 / 726,
}])
write_csv(pd.concat([table, overall], ignore_index=True), "supplementary_table_S7_clinical_concept_concordance.csv")
