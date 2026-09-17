# Supplementary Figure S3 entry point.

project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
source(file.path(project_root, "code", "final_figures", "support", "Figure_S3_label_retrieval_adjudication.R"), chdir = TRUE)
