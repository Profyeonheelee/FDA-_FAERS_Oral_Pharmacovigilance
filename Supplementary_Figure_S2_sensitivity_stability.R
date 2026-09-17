# Supplementary Figure S2 entry point.

project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
source(file.path(project_root, "code", "final_figures", "support", "Figure_S2_sensitivity_stability.R"), chdir = TRUE)
