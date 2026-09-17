# FAERS–FDA Label Oral Signal Discordance

This repository contains the analysis code, locked dictionaries, aggregate FAERS outputs, final label-adjudication data, and publication source files for the study of persistent oral pharmacovigilance signals and their representation in current FDA-approved labeling.

## Key results

- Study period: 2004 Q1–2026 Q2
- Deduplicated, non-deleted FAERS reports: 20,616,119
- Primary drug universe: 1,119 single-ingredient canonical pharmacovigilance ingredients
- Primary oral MedDRA Preferred Terms: 25
- Tested drug–PT pairs: 27,975
- Robust signals: 791
- Persistent robust PT-level signals: 750
- Unique drugs represented among persistent signals: 368
- Drug–clinical concept label-review units: 726
- Explicitly represented: 363
- Broadly represented: 41
- Not identified: 322

## Directory structure

```text
code/
  clean_reproducibility/python/   Core data-processing and signal-analysis scripts
  publication_tables/            Table 1–5 and Supplementary Table S1–S7 scripts
  final_figures/                  Figure 0–4 and Supplementary Figure S1–S4 scripts

data/
  01_reference_and_normalization/ Locked dictionaries and normalization files
  02_faers_aggregates/            Aggregate FAERS counts and processing QC
  03_signal_analysis_primary/     Primary signal-analysis results
  04_signal_analysis_sensitivity/ Sensitivity-analysis results
  05_label_concordance/           Label retrieval, lexical screening, and Step 7B files
  06_publication_outputs/         Step 7C data and publication table/figure source files
  07_supplementary_data/          Supplementary data workbooks

docs/                              Locked analysis plans and correction documentation
figures/                           Figure output directory created at run time
```

## Publication table code

Scripts are named in manuscript order.

### Main tables

1. `Table_1_study_population_and_analysis_flow.py`
2. `Table_2_signal_landscape_by_domain.py`
3. `Table_3_label_concordance_by_domain.py`
4. `Table_4_label_concordance_by_clinical_concept.py`
5. `Table_5_priority_discordant_pairs.py`

### Supplementary tables

1. `Supplementary_Table_S1_oral_adverse_event_ontology.py`
2. `Supplementary_Table_S2_signal_characteristics.py`
3. `Supplementary_Table_S3_sensitivity_analysis.py`
4. `Supplementary_Table_S4_label_retrieval_and_adjudication.py`
5. `Supplementary_Table_S5_domain_comparisons.py`
6. `Supplementary_Table_S6_discordant_unit_characteristics.py`
7. `Supplementary_Table_S7_clinical_concept_concordance.py`

Generate all table source files from the repository root:

```bash
python code/publication_tables/run_all_tables.py
```

Outputs are written to `data/06_publication_outputs/`.

## Publication figure code

### Main figures

- `Figure_0_study_flow.R`
- `Figure_1_persistent_signal_landscape.R`
- `Figure_2_domain_discordance.R`
- `Figure_3_clinical_concept_concordance.R`
- `Figure_4_priority_discordant_pairs.R`

Figure 1 uses the 726 drug–clinical concept review units and displays maximum EB05, co-report count, and final label status. It is not the earlier 750-signal PT-level plot.

### Supplementary figures

- `Supplementary_Figure_S1_temporal_persistence.R`
- `Supplementary_Figure_S2_sensitivity_stability.R`
- `Supplementary_Figure_S3_label_retrieval_adjudication.R`
- `Supplementary_Figure_S4_exploratory_clustered_model.R`

Generate all figures from the repository root:

```bash
Rscript code/final_figures/run_all_figures.R
```

Outputs are written to `figures/` in PNG, TIFF, and PDF formats. SVG output is also written when `svglite` is installed.

## Table 5 and Figure 4 selection rule

Displayed pairs were restricted to persistent robust signals classified as `Not identified`, with at least 20 co-reports. Up to two pairs with the highest EB05 were selected per oral adverse-event domain after excluding direct indication or dosing-context overlap. Fluconazole–oral candidiasis was not prioritized because candidiasis wording occurs in indication and dosing context; cisplatin–oral candidiasis was displayed instead. The full result remains available in the supplementary data.

## Core analysis sequence

The public-facing pipeline scripts are located in `code/clean_reproducibility/python/`:

1. `00_build_drug_master.py`
2. `01_validate_oral_pts.py`
3. `02_process_faers.py`
4. `03_signal_analysis_primary.py`
5. `04_signal_analysis_sensitivity.py`
6. `05_fetch_fda_labels.py`
7. `06_apply_step7C_corrections.py`

Set `FAERS_PROJECT_ROOT` to the repository root when running scripts from another working directory.

```bash
export FAERS_PROJECT_ROOT=/path/to/FAERS_Oral_Signal_Reproducibility_Package_CORRECTED
```

The raw quarterly FAERS ASCII archives and the approximately 1.3-GB cached label-record file are not included. The locked aggregate FAERS files and final adjudication files supplied in this package are sufficient to reproduce the publication tables and figures without reprocessing raw FAERS reports.

## Label adjudication

The automated lexical screen was followed by manual label review. The final Step 7C dataset contains 726 resolved drug–clinical concept units. Five lexical variants were reclassified during Step 7C, and one candidate remained `Not identified` because the matched language occurred in indication or dosing context. The correction audit is provided in `step7C_correction_audit_6_candidates.csv`.

## Software

- Python 3.12 or later
- Python packages listed in `requirements.txt`
- R 4.5 or later
- R packages listed in `R_PACKAGES.txt`

## Integrity verification

Checksums for the corrected package are listed in `MANIFEST.sha256`.

```bash
sha256sum -c MANIFEST.sha256
```
