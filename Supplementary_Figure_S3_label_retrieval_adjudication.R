# Standalone reproduction script for Supplementary Figure S3.
# All required input files are resolved from the repository root.

library(ggplot2)

library(patchwork)

# ------------------------------------------------------------
# Show figure directly in RStudio
# ------------------------------------------------------------
if (Sys.getenv("RSTUDIO") == "1") {
  options(device = "RStudioGD")
}

# ------------------------------------------------------------
# Project folders
# ------------------------------------------------------------
data_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())

analysis_dir <- data_root

output_dir <- file.path(data_root, "figures")

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# ------------------------------------------------------------
# Robust exact-file finder
# ------------------------------------------------------------
find_exact_file <- function(
  filename,
  root_dir = data_root
) {

  direct_candidates <- c(
    file.path(root_dir, filename),
    file.path(root_dir, "FAERS_LABEL_CONCORDANCE", filename),
    file.path(root_dir, "FAERS_PUBLICATION_PACKAGE_v1", filename),
    file.path(root_dir, "FAERS_SIGNAL_ANALYSIS", filename)
  )

  for (p in direct_candidates) {
    if (file.exists(p)) {
      return(
        normalizePath(
          p,
          winslash = "/",
          mustWork = TRUE
        )
      )
    }
  }

  hits <- list.files(
    root_dir,
    pattern = paste0(
      "^",
      gsub(
        "\\.",
        "\\\\.",
        filename
      ),
      "$"
    ),
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(hits) == 0) {
    stop(
      paste0(
        "Could not find required file anywhere under:\n",
        root_dir,
        "\n\nMissing file:\n",
        filename
      )
    )
  }

  if (length(hits) > 1) {
    message(
      "\nMultiple matches found for ",
      filename,
      ". Using:\n",
      hits[1]
    )
  }

  normalizePath(
    hits[1],
    winslash = "/",
    mustWork = TRUE
  )
}

# ------------------------------------------------------------
# Resolve files
# ------------------------------------------------------------
retrieval_qc_file <- find_exact_file(
  "step7A_label_retrieval_QC_by_drug.csv"
)

# The final adjudication file may not exist locally under the exact
# publication-package filename. Figure S3 can still be generated
# from the locked Step 7A–7C counts. If the file is present, use it
# for verification; otherwise fall back to the locked counts below.

find_optional_file <- function(
  filename,
  root_dir = data_root
) {

  direct_candidates <- c(
    file.path(root_dir, filename),
    file.path(root_dir, "FAERS_LABEL_CONCORDANCE", filename),
    file.path(root_dir, "FAERS_PUBLICATION_PACKAGE_v1", filename),
    file.path(root_dir, "FAERS_SIGNAL_ANALYSIS", filename)
  )

  for (p in direct_candidates) {
    if (file.exists(p)) {
      return(
        normalizePath(
          p,
          winslash = "/",
          mustWork = TRUE
        )
      )
    }
  }

  hits <- list.files(
    root_dir,
    pattern = paste0(
      "^",
      gsub("\\.", "\\\\.", filename),
      "$"
    ),
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(hits) == 0) {
    return(NA_character_)
  }

  normalizePath(
    hits[1],
    winslash = "/",
    mustWork = TRUE
  )
}

final_adjudication_file <- find_optional_file(
  "step7C_final_label_adjudication_726_CORRECTED.csv"
)

cat("\nResolved input files\n")
cat("--------------------\n")
cat(
  "Retrieval QC:\n",
  retrieval_qc_file,
  "\n\n"
)

if (!is.na(final_adjudication_file)) {
  cat(
    "Final adjudication:\n",
    final_adjudication_file,
    "\n\n"
  )
} else {
  cat(
    "Final adjudication CSV not found locally.\n",
    "Using locked Step 7A–7C adjudication counts for Panel b.\n\n"
  )
}

# ------------------------------------------------------------
# Read retrieval QC data
# ------------------------------------------------------------
retrieval_qc <- read.csv(
  retrieval_qc_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(
  nrow(retrieval_qc) == 368
)

# Optional final adjudication dataset for verification only.
final_df <- NULL

if (!is.na(final_adjudication_file)) {

  final_df <- read.csv(
    final_adjudication_file,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  stopifnot(
    nrow(final_df) == 726
  )
}

# ============================================================
# PANEL a
# Automated label-retrieval pathway
# ============================================================

retrieval_source <- trimws(
  retrieval_qc$retrieval_source
)

n_application <- sum(
  retrieval_source ==
    "application_number"
)

n_generic <- sum(
  retrieval_source ==
    "generic_name_fallback"
)

n_no_spl <- sum(
  as.numeric(
    retrieval_qc$n_current_SPL_sets_retrieved
  ) == 0,
  na.rm = TRUE
)

retrieval_summary <- data.frame(
  Retrieval = factor(
    c(
      "Application-number linkage",
      "Generic-name fallback",
      "No SPL in automated retrieval"
    ),
    levels = rev(
      c(
        "Application-number linkage",
        "Generic-name fallback",
        "No SPL in automated retrieval"
      )
    )
  ),
  n = c(
    n_application,
    n_generic,
    n_no_spl
  ),
  stringsAsFactors = FALSE
)

retrieval_summary$Percent <- (
  100 *
    retrieval_summary$n /
    nrow(
      retrieval_qc
    )
)

retrieval_summary$Label <- paste0(
  retrieval_summary$n,
  " (",
  sprintf(
    "%.1f",
    retrieval_summary$Percent
  ),
  "%)"
)

# ============================================================
# PANEL b
# Adjudication progression
# ============================================================

# Locked counts from the finalized Step 7A–7C workflow:
# Step 7A automated lexical screen:
#   322 explicit lexical matches
#   14 broad lexical candidates
#   369 no lexical matches
#   21 no label retrieved
#
# Step 7B manual adjudication:
#   359 explicit
#   40 broad
#   327 Not identified
#   0 unresolved
#
# Final Step 7C:
#   363 explicit
#   41 broad
#   322 Not identified
#   0 unresolved

step7a <- c(
  Explicit = 322,
  Broad = 14,
  Not_identified = 369,
  Unresolved = 21
)

step7b <- c(
  Explicit = 359,
  Broad = 40,
  Not_identified = 327,
  Unresolved = 0
)

step7c <- c(
  Explicit = 363,
  Broad = 41,
  Not_identified = 322,
  Unresolved = 0
)

# If the final adjudication CSV is available, verify that its Step 7B
# and Step 7C counts agree with the locked values. The plot itself does
# not depend on the file.
if (!is.null(final_df)) {

  observed_step7b <- c(
    Explicit = sum(
      final_df$step7B_final_label_status ==
        "Explicitly represented"
    ),
    Broad = sum(
      final_df$step7B_final_label_status ==
        "Broadly represented"
    ),
    Not_identified = sum(
      final_df$step7B_final_label_status ==
        "Not identified"
    ),
    Unresolved = 0
  )

  observed_step7c <- c(
    Explicit = sum(
      final_df$final_label_status ==
        "Explicitly represented"
    ),
    Broad = sum(
      final_df$final_label_status ==
        "Broadly represented"
    ),
    Not_identified = sum(
      final_df$final_label_status ==
        "Not identified"
    ),
    Unresolved = 0
  )

  stopifnot(
    all(observed_step7b == step7b),
    all(observed_step7c == step7c)
  )

  message(
    "Final adjudication CSV found: locked Step 7B/7C counts verified."
  )
}

stopifnot(
  sum(step7a) == 726,
  sum(step7b) == 726,
  sum(step7c) == 726
)

status_df <- rbind(
  data.frame(
    Stage = "Step 7A\nAutomated lexical screen",
    Status = names(step7a),
    n = as.numeric(step7a)
  ),
  data.frame(
    Stage = "Step 7B\nManual adjudication",
    Status = names(step7b),
    n = as.numeric(step7b)
  ),
  data.frame(
    Stage = "Step 7C\nFinal adjudication",
    Status = names(step7c),
    n = as.numeric(step7c)
  )
)

status_df$Stage <- factor(
  status_df$Stage,
  levels = c(
    "Step 7A\nAutomated lexical screen",
    "Step 7B\nManual adjudication",
    "Step 7C\nFinal adjudication"
  )
)

status_df$Status <- factor(
  status_df$Status,
  levels = c(
    "Explicit",
    "Broad",
    "Not_identified",
    "Unresolved"
  )
)

status_df$Percent <- (
  100 *
    status_df$n /
    726
)

# Only label segments large enough to read.
status_df$Segment_label <- ifelse(
  status_df$Percent >= 4,
  paste0(
    status_df$n,
    "\n(",
    sprintf(
      "%.1f",
      status_df$Percent
    ),
    "%)"
  ),
  ""
)

# ============================================================
# Colors
# ============================================================

# Panel a: restrained Nature-style tones
retrieval_colors <- c(
  "Application-number linkage" = "#3C5488",
  "Generic-name fallback" = "#8FA9C6",
  "No SPL in automated retrieval" = "#8A8178"
)

# Panel b: harmonized with main Figure 3
col_explicit <- "#00A087"
col_broad <- adjustcolor(
  "#4DBBD5",
  alpha.f = 0.55
)
col_notid <- "#A23B2A"
col_unresolved <- "#555555"

col_text <- "#222222"
col_muted <- "#666666"
col_grid <- "#E7E7E7"

status_colors <- c(
  "Explicit" = col_explicit,
  "Broad" = col_broad,
  "Not_identified" = col_notid,
  "Unresolved" = col_unresolved
)

# ============================================================
# Console output
# ============================================================

cat("\n")
cat("============================================================\n")
cat("SUPPLEMENTARY FIGURE S3 - LABEL RETRIEVAL / ADJUDICATION\n")
cat("============================================================\n")

cat("\nPanel a. Automated retrieval pathway\n")
print(
  retrieval_summary,
  row.names = FALSE
)

cat("\nPanel b. Adjudication progression\n")
print(
  status_df[
    ,
    c(
      "Stage",
      "Status",
      "n",
      "Percent"
    )
  ],
  row.names = FALSE
)

cat("\nFinal Step 7C status\n")
cat(
  "Explicitly represented: ",
  step7c["Explicit"],
  "/726 (",
  sprintf(
    "%.1f",
    100 * step7c["Explicit"] / 726
  ),
  "%)\n",
  sep = ""
)

cat(
  "Broadly represented: ",
  step7c["Broad"],
  "/726 (",
  sprintf(
    "%.1f",
    100 * step7c["Broad"] / 726
  ),
  "%)\n",
  sep = ""
)

cat(
  "Not identified: ",
  step7c["Not_identified"],
  "/726 (",
  sprintf(
    "%.1f",
    100 * step7c["Not_identified"] / 726
  ),
  "%)\n",
  sep = ""
)

cat("Unresolved: 0/726 (0.0%)\n")
cat("============================================================\n\n")

# ============================================================
# PANEL a plot
# ============================================================

p_a <- ggplot(
  retrieval_summary,
  aes(
    x = Percent,
    y = Retrieval,
    fill = Retrieval
  )
) +

  geom_col(
    width = 0.58,
    color = "#6F6F6F",
    linewidth = 0.45
  ) +

  geom_text(
    aes(
      x = Percent + 2.0,
      label = Label
    ),
    family = "sans",
    fontface = "bold",
    size = 3.75,
    hjust = 0,
    color = col_text
  ) +

  scale_fill_manual(
    values = retrieval_colors,
    guide = "none"
  ) +

  scale_x_continuous(
    limits = c(
      0,
      75
    ),
    breaks = seq(
      0,
      70,
      10
    ),
    labels = function(x) {
      paste0(
        x,
        "%"
      )
    },
    expand = c(
      0,
      0
    )
  ) +

  annotate(
    "text",
    x = 74,
    y = 0.55,
    label = "All 5 automated failures\nwere subsequently resolved",
    family = "sans",
    fontface = "bold",
    size = 3.25,
    color = "#555555",
    hjust = 1
  ) +

  labs(
    x = "Proportion of 368 drugs",
    y = NULL,
    tag = "a"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    axis.text.y = element_text(
      size = 11.1,
      color = col_text,
      margin = margin(
        r = 8
      )
    ),

    axis.text.x = element_text(
      size = 10.7,
      color = col_text
    ),

    axis.title.x = element_text(
      size = 12.2,
      face = "bold",
      margin = margin(
        t = 10
      )
    ),

    axis.line.y = element_line(
      color = col_text,
      linewidth = 0.75
    ),
    axis.ticks.y = element_blank(),

    panel.grid.major.x = element_line(
      color = col_grid,
      linewidth = 0.45
    ),

    panel.grid.minor = element_blank(),

    plot.tag = element_text(
      face = "bold",
      size = 15
    ),

    plot.margin = margin(
      t = 8,
      r = 25,
      b = 5,
      l = 5
    )
  )

# ============================================================
# PANEL b plot
# ============================================================

p_b <- ggplot(
  status_df,
  aes(
    x = Stage,
    y = Percent,
    fill = Status
  )
) +

  geom_col(
    width = 0.68,
    color = "white",
    linewidth = 0.45
  ) +

  geom_text(
    aes(
      label = Segment_label
    ),
    position = position_stack(
      vjust = 0.5
    ),
    family = "sans",
    fontface = "bold",
    size = 3.15,
    color = "white",
    lineheight = 0.95
  ) +

  scale_fill_manual(
    values = status_colors,
    labels = c(
      "Explicit" = "Explicitly represented",
      "Broad" = "Broadly represented",
      "Not_identified" = "Not identified",
      "Unresolved" = "No label / unresolved"
    ),
    name = NULL
  ) +

  scale_y_continuous(
    limits = c(
      0,
      100
    ),
    breaks = seq(
      0,
      100,
      20
    ),
    labels = function(x) {
      paste0(
        x,
        "%"
      )
    },
    expand = c(
      0,
      0
    )
  ) +

  labs(
    x = NULL,
    y = "Distribution of 726 review units",
    tag = "b"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    axis.text.x = element_text(
      size = 10.7,
      color = col_text,
      lineheight = 0.95,
      margin = margin(
        t = 8
      )
    ),

    axis.text.y = element_text(
      size = 10.7,
      color = col_text
    ),

    axis.title.y = element_text(
      size = 12.2,
      face = "bold",
      margin = margin(
        r = 10
      )
    ),

    panel.grid.major.y = element_line(
      color = col_grid,
      linewidth = 0.45
    ),

    panel.grid.minor = element_blank(),

    legend.position = "top",
    legend.text = element_text(
      size = 9.8
    ),

    legend.key.width = unit(
      7,
      "mm"
    ),

    plot.tag = element_text(
      face = "bold",
      size = 15
    ),

    plot.margin = margin(
      t = 5,
      r = 5,
      b = 5,
      l = 5
    )
  )

# ============================================================
# Combine
# ============================================================

fig_s3 <- p_a + p_b +
  plot_layout(
    widths = c(
      0.92,
      1.25
    )
  )

# ------------------------------------------------------------
# Display immediately in RStudio
# ------------------------------------------------------------
print(
  fig_s3
)

# ------------------------------------------------------------
# Save source data
# ------------------------------------------------------------
write.csv(
  retrieval_summary,
  file.path(
    output_dir,
    "Supplementary_Figure_S3_panel_a_retrieval_data.csv"
  ),
  row.names = FALSE
)

write.csv(
  status_df,
  file.path(
    output_dir,
    "Supplementary_Figure_S3_panel_b_adjudication_data.csv"
  ),
  row.names = FALSE
)

# ------------------------------------------------------------
# Save figure
# ------------------------------------------------------------
stem <- file.path(
  output_dir,
  "Supplementary_Figure_S3_label_retrieval_adjudication_v3_yaxis_line"
)

ggsave(
  paste0(
    stem,
    ".png"
  ),
  fig_s3,
  width = 205,
  height = 112,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(
    stem,
    ".tiff"
  ),
  fig_s3,
  width = 205,
  height = 112,
  units = "mm",
  dpi = 600,
  compression = "lzw",
  bg = "white"
)

ggsave(
  paste0(
    stem,
    ".pdf"
  ),
  fig_s3,
  width = 205,
  height = 112,
  units = "mm",
  device = cairo_pdf,
  bg = "white"
)

if (
  requireNamespace(
    "svglite",
    quietly = TRUE
  )
) {

  ggsave(
    paste0(
      stem,
      ".svg"
    ),
    fig_s3,
    width = 205,
    height = 112,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

cat("\nSaved Supplementary Figure S3 files to:\n")
cat(
  output_dir,
  "\n"
)

# Keep final figure visible when script finishes.
print(
  fig_s3
)
