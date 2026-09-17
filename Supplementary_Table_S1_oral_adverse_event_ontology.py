#!/usr/bin/env python3
"""Generate Supplementary Table S1: prespecified oral adverse-event ontology."""

from _publication_common import REFERENCE_DIR, read_csv, write_csv


ontology = read_csv(REFERENCE_DIR / "oral_ae_dictionary_v1_1_LOCKED.csv")
columns = [
    "ID",
    "Tier",
    "Domain",
    "Subdomain",
    "Clinical concept",
    "Clinical definition / distinction",
    "MedDRA PT (final)",
    "FDA label synonym candidates",
    "Primary inference",
    "Concept-level merge",
    "openFDA exact match",
    "openFDA report count\n2004Q1–2026Q2",
    "Validation / disposition",
]
write_csv(ontology[columns], "supplementary_table_S1_oral_adverse_event_ontology.csv")
