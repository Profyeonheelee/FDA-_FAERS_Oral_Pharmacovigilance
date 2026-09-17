#!/usr/bin/env python3
"""Generate Supplementary Table S4: label retrieval and adjudication quality control."""

import pandas as pd

from _publication_common import LABEL_DIR, PUBLICATION_DIR, load_final_adjudication, read_csv, write_csv


retrieval = read_csv(LABEL_DIR / "step7A_label_retrieval_QC_by_drug.csv")
screen = read_csv(LABEL_DIR / "step7A_label_lexical_screen.csv")
step7b = read_csv(LABEL_DIR / "step7B/step7B_final_label_adjudication_726_drug_concepts.csv")
final = load_final_adjudication()
correction = read_csv(PUBLICATION_DIR / "step7C_correction_audit_6_candidates.csv")

failed_units = int(final["openFDA_label_retrieval_failed"].astype(str).str.lower().isin(["true", "1", "yes"]).sum())
panel_a = pd.DataFrame([
    ("Unique drugs requiring current-label retrieval", len(retrieval), "100.0%"),
    ("Retrieved by application number", int((retrieval["retrieval_source"] == "application_number").sum()), "32.6%"),
    ("Retrieved by generic-name fallback", int((retrieval["retrieval_source"] == "generic_name_fallback").sum()), "66.0%"),
    ("No current SPL retrieved in automated step", int((retrieval["retrieval_source"] == "none").sum()), "1.4% of drugs"),
    ("Review units affected by automated retrieval failure", failed_units, "2.9% of 726 units"),
    ("Review units resolved through manual review of current DailyMed labeling", failed_units, "2.9% of 726 units"),
    ("Final review units with current label resolved", int((final["current_label_resolved_for_final_adjudication"] == "Yes").sum()), "726/726 (100.0%)"),
    ("Drugs with recorded retrieval error", int(retrieval["retrieval_errors"].notna().sum()), "Automated retrieval QC"),
], columns=["Retrieval_characteristic", "n", "Percent_or_note"])

def stage_counts(series: pd.Series, mapping: dict[str, str]) -> dict[str, int]:
    mapped = series.map(mapping)
    return mapped.value_counts().to_dict()

step7a_counts = stage_counts(screen["auto_primary_label_status"], {
    "Explicit lexical match": "Explicitly represented",
    "Broad lexical candidate": "Broadly represented",
    "No lexical match": "Not identified",
    "No label retrieved": "Unresolved",
})
step7b_counts = step7b["final_label_status"].value_counts().to_dict()
final_counts = final["final_label_status"].value_counts().to_dict()
panel_b = pd.DataFrame([
    ("Step 7A automated lexical screen", step7a_counts.get("Explicitly represented", 0), step7a_counts.get("Broadly represented", 0), step7a_counts.get("Not identified", 0), step7a_counts.get("Unresolved", 0), 726),
    ("Step 7B manual adjudication", step7b_counts.get("Explicitly represented", 0), step7b_counts.get("Broadly represented", 0), step7b_counts.get("Not identified", 0), 0, 726),
    ("Step 7C strict lexical correction", final_counts.get("Explicitly represented", 0), final_counts.get("Broadly represented", 0), final_counts.get("Not identified", 0), 0, 726),
], columns=["Adjudication_stage", "Explicitly_represented", "Broadly_represented", "Not_identified", "Unresolved", "Total"])

write_csv(panel_a, "supplementary_table_S4_panel_A_label_retrieval.csv")
write_csv(panel_b, "supplementary_table_S4_panel_B_adjudication_progression.csv")
write_csv(correction, "supplementary_table_S4_panel_C_step7C_correction_audit.csv")
