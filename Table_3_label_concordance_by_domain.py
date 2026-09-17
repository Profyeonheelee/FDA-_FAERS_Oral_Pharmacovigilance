#!/usr/bin/env python3
"""Generate Table 3: FDA-label concordance by oral adverse-event domain."""

import pandas as pd
from scipy.stats import chi2_contingency

from _publication_common import DOMAIN_ORDER, PUBLICATION_DIR, load_final_adjudication, read_csv, wilson_interval, write_csv


data = load_final_adjudication()
rows = []
for domain in DOMAIN_ORDER + ["Overall"]:
    subset = data if domain == "Overall" else data[data["Domain"] == domain]
    n = len(subset)
    explicit = int((subset["final_label_status"] == "Explicitly represented").sum())
    broad = int((subset["final_label_status"] == "Broadly represented").sum())
    not_identified = int((subset["final_label_status"] == "Not identified").sum())
    rows.append({
        "Domain": domain,
        "review_units": n,
        "Explicitly_represented_n": explicit,
        "Explicitly_represented_pct": 100 * explicit / n,
        "Broadly_represented_n": broad,
        "Broadly_represented_pct": 100 * broad / n,
        "Represented_total_n": explicit + broad,
        "Represented_total_pct": 100 * (explicit + broad) / n,
        "Not_identified_n": not_identified,
        "Not_identified_pct": 100 * not_identified / n,
        "Unresolved_n": n - explicit - broad - not_identified,
        "primary_denominator": n,
    })

table = pd.DataFrame(rows)
write_csv(table, "table3_FDA_label_concordance_by_domain.csv")

figure = table[table["Domain"] != "Overall"].copy()
intervals = [wilson_interval(int(row.Not_identified_n), int(row.review_units)) for row in figure.itertuples()]
figure["Not_identified_CI95_low"] = [x[0] for x in intervals]
figure["Not_identified_CI95_high"] = [x[1] for x in intervals]
contingency = figure[["Not_identified_n", "Represented_total_n"]].to_numpy()
_, overall_p, _, _ = chi2_contingency(contingency)
cluster = read_csv(PUBLICATION_DIR / "step7C_domain_cluster_robust_sensitivity.csv").iloc[0]
figure["overall_Pearson_chi2_p"] = overall_p
figure["cluster_robust_domain_p"] = cluster["p_value"]
write_csv(figure, "figure2_domain_discordance_data.csv")
