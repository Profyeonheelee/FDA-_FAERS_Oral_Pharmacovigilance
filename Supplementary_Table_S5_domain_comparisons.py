#!/usr/bin/env python3
"""Generate Supplementary Table S5: overall and pairwise domain comparisons."""

import itertools

import numpy as np
import pandas as pd
from scipy.stats import chi2_contingency, fisher_exact

from _publication_common import DOMAIN_ORDER, PUBLICATION_DIR, load_final_adjudication, read_csv, write_csv


data = load_final_adjudication()
domain_counts = {}
for domain in DOMAIN_ORDER:
    subset = data[data["Domain"] == domain]
    not_identified = int((subset["final_label_status"] == "Not identified").sum())
    domain_counts[domain] = (not_identified, len(subset) - not_identified)

contingency = [[domain_counts[d][0], domain_counts[d][1]] for d in DOMAIN_ORDER]
chi2, p_value, df, _ = chi2_contingency(contingency)
cluster = read_csv(PUBLICATION_DIR / "step7C_domain_cluster_robust_sensitivity.csv").iloc[0]
panel_a = pd.DataFrame([
    ("Primary domain comparison", "Pearson chi-square", chi2, df, p_value),
    ("Ingredient-clustered sensitivity analysis", "Wald chi-square", cluster["wald_chi2"], int(cluster["df"]), cluster["p_value"]),
], columns=["Analysis", "Test", "Statistic", "df", "P_value"])

rows = []
for domain_1, domain_2 in itertools.combinations(DOMAIN_ORDER, 2):
    n1, r1 = domain_counts[domain_1]
    n2, r2 = domain_counts[domain_2]
    p = fisher_exact([[n1, r1], [n2, r2]], alternative="two-sided").pvalue
    rows.append({
        "Domain_1": domain_1,
        "Not_identified_1": n1,
        "Represented_1": r1,
        "Domain_2": domain_2,
        "Not_identified_2": n2,
        "Represented_2": r2,
        "Difference_percentage_points": 100 * n1 / (n1 + r1) - 100 * n2 / (n2 + r2),
        "Fisher_p": p,
    })
panel_b = pd.DataFrame(rows)
order = np.argsort(panel_b["Fisher_p"].to_numpy())
ranked = panel_b["Fisher_p"].to_numpy()[order]
adjusted = ranked * len(ranked) / np.arange(1, len(ranked) + 1)
adjusted = np.minimum.accumulate(adjusted[::-1])[::-1]
q_values = np.empty_like(adjusted)
q_values[order] = np.minimum(adjusted, 1.0)
panel_b["BH_FDR_q"] = q_values
panel_b["FDR_significant"] = panel_b["BH_FDR_q"] < 0.05

write_csv(panel_a, "supplementary_table_S5_panel_A_overall_tests.csv")
write_csv(panel_b, "supplementary_table_S5_panel_B_pairwise_domain_tests.csv")
