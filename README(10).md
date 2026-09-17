# FAERS–FDA Label Oral Signal Discordance

This repository contains analysis code, locked reference files, aggregate FAERS outputs, final label-adjudication data, and publication source files for a study of persistent oral pharmacovigilance signals and their representation in current FDA-approved labeling.

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

## Repository organization

All files are stored in the repository root. File prefixes identify their roles.

| File pattern | Contents |
|---|---|
| `00_*.py` to `06_*.py` | Core data-processing, signal-analysis, label-retrieval, and correction scripts |
| `Table_*.py` | Main Table 1–5 source-generation scripts |
| `Supplementary_Table_*.py` | Supplementary Table S1–S7 source-generation scripts |
| `Figure_*.R` | Main Figure 0–4 scripts |
| `Supplementary_Figure_*.R` | Supplementary Figure S1–S4 scripts |
| `table*.csv`, `figure*.csv`, and `supplementary_table*.csv` | Publication table and figure source data |
| `step*.csv` and `faers*.csv` | Intermediate and final aggregate analysis outputs |
| `*_LOCKED.*` | Locked dictionaries, analysis specifications, and reference files |
| `Supplementary Data 1_*.xlsx` | Complete set of 791 robust primary signals |
| `Supplementary Data 2_*.xlsx` | Expanded high-strength signal–label discordant pairs |
| `run_all_tables.py` | Runs all main and supplementary table scripts |
| `run_all_figures.R` | Runs all main and supplementary figure scripts |
| `requirements.txt` and `R_PACKAGES.txt` | Required Python and R packages |
| `MANIFEST.sha256` | File-integrity checksums |

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
python run_all_tables.py
```

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
Rscript run_all_figures.R
```

Figure outputs are written in PNG, TIFF, and PDF formats. SVG output is also written when `svglite` is installed.

## Table 5 and Figure 4 selection rule

Displayed pairs were restricted to persistent robust signals classified as `Not identified`, with at least 20 co-reports. Up to two pairs with the highest EB05 were selected per oral adverse-event domain after excluding direct indication or dosing-context overlap. Fluconazole–oral candidiasis was not prioritized because candidiasis wording occurs in indication and dosing context; cisplatin–oral candidiasis was displayed instead. The full result remains available in Supplementary Data 2.

## Core analysis sequence

The core scripts should be run in numerical order:

1. `00_build_drug_master.py`
2. `01_validate_oral_pts.py`
3. `02_process_faers.py`
4. `03_signal_analysis_primary.py`
5. `04_signal_analysis_sensitivity.py`
6. `05_fetch_fda_labels.py`
7. `06_apply_step7C_corrections.py`

Set `FAERS_PROJECT_ROOT` to the repository root when running scripts from another working directory.

```bash
export FAERS_PROJECT_ROOT=/path/to/FDA_FAERS_Oral_Pharmacovigilance
```

The raw quarterly FAERS ASCII archives and the approximately 1.3-GB cached label-record file are not included. The aggregate FAERS files and final adjudication files are provided to support reproduction of the publication tables and figures without reprocessing the raw reports.

## Supplementary data

- `Supplementary Data 1_All_791_Robust_Primary_Signals.xlsx` contains all 791 robust primary drug–PT signals.
- `Supplementary Data 2_Expanded_High_Strength_Discordant_Pairs.xlsx` contains the expanded set of high-strength discordant pairs used for detailed review and prioritization.

## Label adjudication

The automated lexical screen was followed by manual label review. The final Step 7C dataset contains 726 resolved drug–clinical concept units. Five lexical variants were reclassified during Step 7C, and one candidate remained `Not identified` because the matched language occurred in indication or dosing context. The correction audit is provided in `step7C_correction_audit_6_candidates.csv`.

## Software

- Python 3.12 or later
- Python packages listed in `requirements.txt`
- R 4.5 or later
- R packages listed in `R_PACKAGES.txt`

## Integrity verification

Checksums are listed in `MANIFEST.sha256`.

```bash
sha256sum -c MANIFEST.sha256
```

## Citation

Please cite the associated manuscript when using the code or data from this repository. Full citation information will be added after publication.
