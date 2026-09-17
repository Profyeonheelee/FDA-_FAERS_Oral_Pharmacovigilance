# Standalone reproduction script for Supplementary Figure S2.
# All required input files are resolved from the repository root.

library(ggplot2)

library(patchwork)

# ------------------------------------------------------------
# Show plots directly in the RStudio Plots pane
# ------------------------------------------------------------
if (Sys.getenv("RSTUDIO") == "1") {
  options(device = "RStudioGD")
}

# ------------------------------------------------------------
# Input / output
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
# Robust input-file finder
#
# Step 6B files may have been written either directly under
# FDA_opendata or inside FAERS_SIGNAL_ANALYSIS. Rather than
# forcing one location, search the project tree for the exact
# file name and use the first exact match.
# ------------------------------------------------------------
find_exact_file <- function(
  filename,
  preferred_dir = analysis_dir,
  root_dir = data_root
) {

  preferred_path <- file.path(
    preferred_dir,
    filename
  )

  if (file.exists(preferred_path)) {
    return(
      normalizePath(
        preferred_path,
        winslash = "/",
        mustWork = TRUE
      )
    )
  }

  root_path <- file.path(
    root_dir,
    filename
  )

  if (file.exists(root_path)) {
    return(
      normalizePath(
        root_path,
        winslash = "/",
        mustWork = TRUE
      )
    )
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

primary_robust_file <- find_exact_file(
  "step6_primary_robust_signals.csv"
)

primary_persistent_file <- find_exact_file(
  "step6_primary_robust_temporally_repeated.csv"
)

sensitivity_robust_file <- find_exact_file(
  "step6B_sensitivity_robust_signals.csv"
)

sensitivity_persistent_file <- find_exact_file(
  "step6B_sensitivity_robust_temporally_repeated.csv"
)

cat("\nResolved input files\n")
cat("--------------------\n")
cat(
  "Primary robust:\n",
  primary_robust_file,
  "\n\n"
)
cat(
  "Primary persistent:\n",
  primary_persistent_file,
  "\n\n"
)
cat(
  "Sensitivity robust:\n",
  sensitivity_robust_file,
  "\n\n"
)
cat(
  "Sensitivity persistent:\n",
  sensitivity_persistent_file,
  "\n\n"
)

# ------------------------------------------------------------
# Read data
# ------------------------------------------------------------
primary_robust <- read.csv(
  primary_robust_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

primary_persistent <- read.csv(
  primary_persistent_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

sensitivity_robust <- read.csv(
  sensitivity_robust_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

sensitivity_persistent <- read.csv(
  sensitivity_persistent_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# ------------------------------------------------------------
# Domain order
# ------------------------------------------------------------
domain_order <- c(
  "Salivary dysfunction",
  "Oral mucosal / tongue",
  "Taste / chemosensory",
  "Jaw / alveolar bone",
  "Oral infection",
  "Dental / pulpal",
  "Gingival / periodontal"
)

display_order <- c(
  domain_order,
  "Overall"
)

# ------------------------------------------------------------
# Pair identifier
# ------------------------------------------------------------
pair_id <- function(df) {
  paste(
    df$canonical_pharmacovigilance_ingredient,
    df$MedDRA_PT,
    sep = "___"
  )
}

# ------------------------------------------------------------
# Summarize counts by domain
# ------------------------------------------------------------
count_by_domain <- function(df) {

  x <- table(
    factor(
      df$Domain,
      levels = domain_order
    )
  )

  out <- data.frame(
    Domain = domain_order,
    n = as.integer(x),
    stringsAsFactors = FALSE
  )

  out
}

pr <- count_by_domain(primary_robust)
sr <- count_by_domain(sensitivity_robust)

pp <- count_by_domain(primary_persistent)
sp <- count_by_domain(sensitivity_persistent)

robust_summary <- merge(
  pr,
  sr,
  by = "Domain",
  suffixes = c("_Primary", "_Sensitivity"),
  sort = FALSE
)

persistent_summary <- merge(
  pp,
  sp,
  by = "Domain",
  suffixes = c("_Primary", "_Sensitivity"),
  sort = FALSE
)

# Restore domain order after merge.
robust_summary <- robust_summary[
  match(
    domain_order,
    robust_summary$Domain
  ),
]

persistent_summary <- persistent_summary[
  match(
    domain_order,
    persistent_summary$Domain
  ),
]

# ------------------------------------------------------------
# Add overall row
# ------------------------------------------------------------
robust_summary <- rbind(
  robust_summary,
  data.frame(
    Domain = "Overall",
    n_Primary = nrow(primary_robust),
    n_Sensitivity = nrow(sensitivity_robust)
  )
)

persistent_summary <- rbind(
  persistent_summary,
  data.frame(
    Domain = "Overall",
    n_Primary = nrow(primary_persistent),
    n_Sensitivity = nrow(sensitivity_persistent)
  )
)

# ------------------------------------------------------------
# Verify complete primary recovery
# ------------------------------------------------------------
primary_robust_ids <- pair_id(
  primary_robust
)

sensitivity_robust_ids <- pair_id(
  sensitivity_robust
)

primary_persistent_ids <- pair_id(
  primary_persistent
)

sensitivity_persistent_ids <- pair_id(
  sensitivity_persistent
)

robust_recovered <- sum(
  primary_robust_ids %in%
    sensitivity_robust_ids
)

persistent_recovered <- sum(
  primary_persistent_ids %in%
    sensitivity_persistent_ids
)

stopifnot(
  robust_recovered ==
    nrow(primary_robust)
)

stopifnot(
  persistent_recovered ==
    nrow(primary_persistent)
)

# ------------------------------------------------------------
# Sensitivity-only counts
# ------------------------------------------------------------
robust_summary$Additional <- (
  robust_summary$n_Sensitivity -
    robust_summary$n_Primary
)

persistent_summary$Additional <- (
  persistent_summary$n_Sensitivity -
    persistent_summary$n_Primary
)

robust_summary$Additional_label <- paste0(
  "+",
  robust_summary$Additional
)

persistent_summary$Additional_label <- paste0(
  "+",
  persistent_summary$Additional
)

# ------------------------------------------------------------
# Factor order
# Reverse so the first domain appears at the top.
# ------------------------------------------------------------
robust_summary$Domain <- factor(
  robust_summary$Domain,
  levels = rev(
    display_order
  )
)

persistent_summary$Domain <- factor(
  persistent_summary$Domain,
  levels = rev(
    display_order
  )
)

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------
col_primary <- "#2F4F7F"                         # deeper muted navy
col_primary_border <- "#5F6875"                  # subtle grey-blue outline
col_sensitivity <- adjustcolor("#9D6B53", alpha.f = 0.55)  # semi-transparent warm brown
col_sensitivity_border <- "#5B4034"              # darker brown outline for overlap
col_sensitivity_text <- "#7A4A36"                # solid dark brown for +n labels
col_connector <- "#B7B7B7"
col_text <- "#222222"
col_muted <- "#666666"
col_grid <- "#E7E7E7"
col_overall <- "#555555"

# ------------------------------------------------------------
# Console output
# ------------------------------------------------------------
cat("\n")
cat("============================================================\n")
cat("SUPPLEMENTARY FIGURE S2 - SENSITIVITY ANALYSIS STABILITY\n")
cat("============================================================\n")

cat("\nRobust signals\n")
print(
  robust_summary[
    rev(
      seq_len(
        nrow(
          robust_summary
        )
      )
    ),
  ],
  row.names = FALSE
)

cat("\nPersistent robust signals\n")
print(
  persistent_summary[
    rev(
      seq_len(
        nrow(
          persistent_summary
        )
      )
    ),
  ],
  row.names = FALSE
)

cat("\nRecovery checks\n")
cat(
  "Primary robust recovered: ",
  robust_recovered,
  "/",
  nrow(
    primary_robust
  ),
  " (100.0%)\n",
  sep = ""
)

cat(
  "Primary persistent robust recovered: ",
  persistent_recovered,
  "/",
  nrow(
    primary_persistent
  ),
  " (100.0%)\n",
  sep = ""
)

cat("============================================================\n\n")

# ------------------------------------------------------------
# Shared plotting function
# ------------------------------------------------------------
make_paired_plot <- function(
  dat,
  panel_tag,
  x_label,
  annotation_text
) {

  max_x <- max(
    dat$n_Sensitivity
  )

  ggplot(
    dat,
    aes(
      y = Domain
    )
  ) +

    # Connector
    geom_segment(
      aes(
        x = n_Primary,
        xend = n_Sensitivity,
        yend = Domain
      ),
      linewidth = 1.15,
      color = col_connector,
      lineend = "round"
    ) +

    # Primary point
    geom_point(
      aes(
        x = n_Primary
      ),
      shape = 21,
      size = 6.0,
      stroke = 0.65,
      fill = col_primary,
      color = col_primary_border
    ) +

    # Sensitivity point
    geom_point(
      aes(
        x = n_Sensitivity
      ),
      shape = 21,
      size = 6.4,
      stroke = 1.05,
      fill = col_sensitivity,
      color = col_sensitivity_border
    ) +

    # Additional sensitivity-only signals
    geom_text(
      aes(
        x = n_Sensitivity +
          max_x * 0.025,
        label = Additional_label
      ),
      family = "sans",
      fontface = "bold",
      size = 3.55,
      hjust = 0,
      color = col_sensitivity_text
    ) +

    # Direct labels for primary counts
    geom_text(
      aes(
        x = n_Primary -
          max_x * 0.018,
        label = n_Primary
      ),
      family = "sans",
      size = 3.15,
      hjust = 1,
      color = col_primary
    ) +

    scale_x_continuous(
      limits = c(
        0,
        max_x * 1.14
      ),
      expand = c(
        0,
        0
      )
    ) +

    coord_cartesian(
      clip = "off"
    ) +

    annotate(
      "text",
      x = max_x * 0.99,
      y = length(
        display_order
      ) + 0.32,
      label = annotation_text,
      family = "sans",
      fontface = "bold",
      size = 3.15,
      color = col_overall,
      hjust = 1
    ) +

    labs(
      x = x_label,
      y = NULL,
      tag = panel_tag
    ) +

    theme_classic(
      base_family = "sans",
      base_size = 12
    ) +

    theme(
      axis.text.y = element_text(
        size = 11.0,
        color = col_text,
        margin = margin(
          r = 8
        )
      ),

      axis.text.x = element_text(
        size = 10.8,
        color = col_text
      ),

      axis.title.x = element_text(
        size = 12.2,
        face = "bold",
        margin = margin(
          t = 10
        )
      ),

      axis.line.y = element_blank(),
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
        t = 15,
        r = 26,
        b = 5,
        l = 5
      )
    )
}

# ------------------------------------------------------------
# Panel a
# ------------------------------------------------------------
p_a <- make_paired_plot(
  robust_summary,
  "a",
  "Number of robust signals",
  "All 791 primary robust signals recovered"
)

# ------------------------------------------------------------
# Panel b
# ------------------------------------------------------------
p_b <- make_paired_plot(
  persistent_summary,
  "b",
  "Number of persistent robust signals",
  "All 750 primary persistent signals recovered"
)

# ------------------------------------------------------------
# Legend
# Construct a compact shared legend using dummy aesthetics.
# ------------------------------------------------------------
legend_df <- data.frame(
  x = c(
    1,
    2
  ),
  y = c(
    1,
    1
  ),
  Analysis = factor(
    c(
      "Primary analysis",
      "Sensitivity analysis"
    ),
    levels = c(
      "Primary analysis",
      "Sensitivity analysis"
    )
  )
)

legend_plot <- ggplot(
  legend_df,
  aes(
    x = x,
    y = y,
    fill = Analysis
  )
) +
  geom_point(
    shape = 21,
    size = 5.8,
    stroke = 0.8,
    color = "#666666"
  ) +
  scale_fill_manual(
    values = c(
      "Primary analysis" = col_primary,
      "Sensitivity analysis" = col_sensitivity
    )
  ) +
  guides(
    fill = guide_legend(
      title = NULL,
      override.aes = list(
        shape = 21,
        size = 5.8,
        stroke = 0.8,
        color = "#666666"
      )
    )
  ) +
  theme_void(
    base_family = "sans"
  ) +
  theme(
    legend.position = "top",
    legend.text = element_text(
      size = 11.0
    )
  )

legend_grob <- patchwork::wrap_elements(
  full = ggplotGrob(
    legend_plot
  )
)

# Simpler publication layout: panels with a shared textual key at top.
fig_s2 <- (
  p_a +
    p_b
) +
  plot_layout(
    widths = c(
      1,
      1
    )
  ) +
  plot_annotation(
    subtitle = "● Primary analysis    ● Sensitivity analysis",
    theme = theme(
      plot.subtitle = element_text(
        family = "sans",
        size = 11.2,
        color = col_muted,
        hjust = 0.5,
        margin = margin(
          b = 3
        )
      )
    )
  )

# ------------------------------------------------------------
# Display in RStudio
# ------------------------------------------------------------
print(
  fig_s2
)

# ------------------------------------------------------------
# Save source data
# ------------------------------------------------------------
write.csv(
  robust_summary,
  file.path(
    output_dir,
    "Supplementary_Figure_S2_panel_a_robust_counts.csv"
  ),
  row.names = FALSE
)

write.csv(
  persistent_summary,
  file.path(
    output_dir,
    "Supplementary_Figure_S2_panel_b_persistent_counts.csv"
  ),
  row.names = FALSE
)

# ------------------------------------------------------------
# Save figure
# ------------------------------------------------------------
stem <- file.path(
  output_dir,
  "Supplementary_Figure_S2_sensitivity_stability_v5_dark_brown_labels"
)

ggsave(
  paste0(
    stem,
    ".png"
  ),
  fig_s2,
  width = 205,
  height = 118,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(
    stem,
    ".tiff"
  ),
  fig_s2,
  width = 205,
  height = 118,
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
  fig_s2,
  width = 205,
  height = 118,
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
    fig_s2,
    width = 205,
    height = 118,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

cat("\nSaved Supplementary Figure S2 files to:\n")
cat(
  output_dir,
  "\n"
)

# Keep final figure visible in RStudio.
print(
  fig_s2
)
