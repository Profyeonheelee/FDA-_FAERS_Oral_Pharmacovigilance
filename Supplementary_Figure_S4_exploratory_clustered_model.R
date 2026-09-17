# Supplementary Figure S4 entry point.

project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
source(file.path(project_root, "code", "final_figures", "support", "Figure_S4_exploratory_clustered_model.R"), chdir = TRUE)
