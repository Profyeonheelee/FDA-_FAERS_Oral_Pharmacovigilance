#!/usr/bin/env python3
"""Generate Table 4: FDA-label concordance by clinical concept."""

import pandas as pd

from _publication_common import CONCEPT_ORDER, DOMAIN_ORDER, PUBLICATION_DIR, load_final_adjudication, read_csv, write_csv


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
            "review_units": n,
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
write_csv(table, "table4_FDA_label_concordance_by_clinical_concept.csv")
write_csv(table.copy(), "figure3_clinical_concept_concordance_data.csv")
figure1 = read_csv(PUBLICATION_DIR / "Supplementary_Figure_S4_model_input.csv")
write_csv(figure1, "figure1_review_unit_landscape_data.csv")
