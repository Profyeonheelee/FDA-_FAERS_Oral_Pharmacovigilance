# Supplementary Figure S1 entry point.

project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
source(file.path(project_root, "code", "final_figures", "support", "Figure_S1_temporal_persistence.R"), chdir = TRUE)
