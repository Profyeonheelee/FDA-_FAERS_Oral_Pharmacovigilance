# Reproduction script for the associated manuscript figure.
# Set FAERS_PROJECT_ROOT to the repository root when running outside the project directory.

library(ggplot2)
library(grid)

# ------------------------------------------------------------
# Output folder
# ------------------------------------------------------------
project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
output_dir <- file.path(project_root, "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Nature-compatible restrained palette
# ------------------------------------------------------------
col_negative <- "#3C5488"   # significant lower discordance
col_positive <- "#A23B2A"   # significant higher discordance, dark red-brown
col_ns_line  <- "#B7B7B7"   # non-significant CI / whisker
col_ns_point <- "#222222"   # non-significant point
col_slate    <- "#8491B4"
col_text     <- "#222222"
col_muted    <- "#666666"
col_grid     <- "#E6E6E6"
col_light    <- "#F7F7F7"

# ------------------------------------------------------------
# Locked Step 7C results
# ------------------------------------------------------------
df <- data.frame(
  Domain = c(
    "Salivary dysfunction",
    "Oral mucosal / tongue",
    "Taste / chemosensory",
    "Jaw / alveolar bone",
    "Oral infection",
    "Dental / pulpal",
    "Gingival / periodontal"
  ),
  review_units = c(151, 223, 154, 16, 43, 71, 68),
  represented_n = c(118, 140, 89, 9, 16, 17, 15),
  not_identified_n = c(33, 83, 65, 7, 27, 54, 53),
  not_identified_pct = c(
    21.8543046358,
    37.2197309417,
    42.2077922078,
    43.7500000000,
    62.7906976744,
    76.0563380282,
    77.9411764706
  ),
  ci_low = c(
    16.0060566759,
    31.1419383373,
    34.6901745381,
    23.0986524055,
    47.8598091597,
    64.9587791439,
    66.7432612289
  ),
  ci_high = c(
    29.0990846426,
    43.7303798464,
    50.1046948332,
    66.8214436012,
    75.6236609903,
    84.4790599670,
    86.1509876127
  ),
  stringsAsFactors = FALSE
)

source_file <- file.path(
  project_root, "data", "06_publication_outputs", "figure2_domain_discordance_data.csv"
)
source_data <- read.csv(source_file, stringsAsFactors = FALSE, check.names = FALSE)
df <- data.frame(
  Domain = source_data$Domain,
  review_units = source_data$review_units,
  represented_n = source_data$Represented_total_n,
  not_identified_n = source_data$Not_identified_n,
  not_identified_pct = source_data$Not_identified_pct,
  ci_low = source_data$Not_identified_CI95_low,
  ci_high = source_data$Not_identified_CI95_high,
  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# Locked overall tests
# ------------------------------------------------------------
overall_discordance <- 322 / 726 * 100

pearson_chi2 <- 101.77504019344573
pearson_df   <- 6
pearson_p    <- unique(source_data$overall_Pearson_chi2_p)

cluster_wald <- 85.71284648258494
cluster_df   <- 6
cluster_p    <- unique(source_data$cluster_robust_domain_p)

# ------------------------------------------------------------
# Domain-specific significance:
# each domain vs all other domains combined
# Fisher exact test, BH-FDR across the 7 tests
# ------------------------------------------------------------
total_not <- sum(df$not_identified_n)
total_rep <- sum(df$represented_n)

df$p_one_vs_rest <- NA_real_
df$rest_discordance_pct <- NA_real_

for (i in seq_len(nrow(df))) {

  this_not <- df$not_identified_n[i]
  this_rep <- df$represented_n[i]

  rest_not <- total_not - this_not
  rest_rep <- total_rep - this_rep

  tab <- matrix(
    c(
      this_not, this_rep,
      rest_not, rest_rep
    ),
    nrow = 2,
    byrow = TRUE
  )

  df$p_one_vs_rest[i] <- fisher.test(
    tab,
    alternative = "two.sided"
  )$p.value

  df$rest_discordance_pct[i] <- 100 * rest_not / (rest_not + rest_rep)
}

df$q_one_vs_rest <- p.adjust(
  df$p_one_vs_rest,
  method = "BH"
)

# Direction is defined against all other domains combined
df$direction <- ifelse(
  df$q_one_vs_rest < 0.05 &
    df$not_identified_pct < df$rest_discordance_pct,
  "Significantly lower",
  ifelse(
    df$q_one_vs_rest < 0.05 &
      df$not_identified_pct > df$rest_discordance_pct,
    "Significantly higher",
    "Not significant"
  )
)

df$plot_color <- ifelse(
  df$direction == "Significantly lower",
  col_negative,
  ifelse(
    df$direction == "Significantly higher",
    col_positive,
    col_ns_point
  )
)

df$line_color <- ifelse(
  df$direction == "Significantly lower",
  col_negative,
  ifelse(
    df$direction == "Significantly higher",
    col_positive,
    col_ns_line
  )
)

# ------------------------------------------------------------
# Order from low to high discordance
# ------------------------------------------------------------
domain_order <- df$Domain[
  order(df$not_identified_pct, decreasing = TRUE)
]
df$Domain <- factor(
  df$Domain,
  levels = domain_order
)

# ------------------------------------------------------------
# Labels
# ------------------------------------------------------------
df$count_label <- paste0(
  df$not_identified_n, "/", df$review_units,
  "  (", sprintf("%.1f", df$not_identified_pct), "%)"
)

df$q_label <- ifelse(
  df$q_one_vs_rest < 0.001,
  paste0("q=", formatC(
    df$q_one_vs_rest,
    format = "e",
    digits = 1
  )),
  paste0("q=", sprintf("%.3f", df$q_one_vs_rest))
)

df$display_label <- ifelse(
  df$direction == "Not significant",
  df$count_label,
  paste0(df$count_label, "   ", df$q_label)
)

# ------------------------------------------------------------
# Console results
# ------------------------------------------------------------
cat("\n")
cat("====================================================================\n")
cat("FIGURE 2 - DOMAIN-SPECIFIC SIGNAL-LABEL DISCORDANCE\n")
cat("====================================================================\n")

console_df <- df[
  order(df$not_identified_pct),
  c(
    "Domain",
    "review_units",
    "not_identified_n",
    "not_identified_pct",
    "ci_low",
    "ci_high",
    "rest_discordance_pct",
    "p_one_vs_rest",
    "q_one_vs_rest",
    "direction"
  )
]

console_df$not_identified_pct <- round(
  console_df$not_identified_pct, 1
)
console_df$ci_low <- round(console_df$ci_low, 1)
console_df$ci_high <- round(console_df$ci_high, 1)
console_df$rest_discordance_pct <- round(
  console_df$rest_discordance_pct, 1
)

print(console_df, row.names = FALSE)

cat("\nColor rule\n")
cat("----------\n")
cat("Dark blue  : significantly LOWER discordance than all other domains\n")
cat("Dark red   : significantly HIGHER discordance than all other domains\n")
cat("Black/grey : not significant after BH-FDR across 7 one-vs-rest tests\n")

cat("\nOverall domain comparison\n")
cat("-------------------------\n")
cat(sprintf(
  "Pearson chi-square(%d) = %.2f, P = %.3e\n",
  pearson_df, pearson_chi2, pearson_p
))
cat(sprintf(
  "Ingredient-clustered Wald chi-square(%d) = %.2f, P = %.3e\n",
  cluster_df, cluster_wald, cluster_p
))
cat("====================================================================\n\n")

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------
p <- ggplot(
  df,
  aes(
    x = not_identified_pct,
    y = Domain
  )
) +

  # Overall reference line
  geom_vline(
    xintercept = overall_discordance,
    linewidth = 0.70,
    linetype = "22",
    color = col_slate
  ) +

  # CI whiskers colored by significance/direction
  geom_segment(
    aes(
      x = ci_low,
      xend = ci_high,
      y = Domain,
      yend = Domain,
      color = direction
    ),
    linewidth = 1.35,
    lineend = "round"
  ) +

  # CI end caps
  geom_errorbar(
    aes(
      xmin = ci_low,
      xmax = ci_high,
      color = direction
    ),
    orientation = "y",
    width = 0.13,
    linewidth = 0.95
  ) +

  # Points
  geom_point(
    aes(
      fill = direction,
      color = direction
    ),
    shape = 21,
    size = 5.6,
    stroke = 1.15
  ) +

  # n/N, %, and q-value for significant domains
  geom_text(
    aes(
      x = pmin(ci_high + 3.2, 89),
      label = display_label
    ),
    family = "sans",
    fontface = "bold",
    size = 3.9,
    hjust = 0,
    color = col_text
  ) +

  # Overall discordance label
  annotate(
    "label",
    x = overall_discordance,
    y = 7.42,
    label = paste0(
      "Overall discordance\n",
      sprintf("%.1f%%", overall_discordance)
    ),
    family = "sans",
    fontface = "bold",
    size = 3.45,
    lineheight = 0.95,
    label.size = 0,
    fill = "white",
    color = col_slate
  ) +

  # Overall test annotation
  annotate(
    "rect",
    xmin = 58,
    xmax = 99,
    ymin = 7.00,
    ymax = 7.80,
    fill = col_light,
    color = NA
  ) +

  annotate(
    "text",
    x = 98,
    y = 7.59,
    hjust = 1,
    label = "Overall domain effect",
    family = "sans",
    fontface = "bold",
    size = 3.6,
    color = col_text
  ) +

  annotate(
    "text",
    x = 98,
    y = 7.34,
    hjust = 1,
    label = "Pearson chi-square(6) = 101.78, P = 1.07 x 10^-19",
    family = "sans",
    size = 3.2,
    color = col_text
  ) +

  annotate(
    "text",
    x = 98,
    y = 7.11,
    hjust = 1,
    label = "Ingredient-clustered sensitivity: Wald chi-square(6) = 85.71, P = 2.35 x 10^-16",
    family = "sans",
    size = 3.0,
    color = col_muted
  ) +

  # Color mapping
  scale_color_manual(
    values = c(
      "Significantly lower" = col_negative,
      "Not significant" = col_ns_line,
      "Significantly higher" = col_positive
    ),
    breaks = c(
      "Significantly lower",
      "Not significant",
      "Significantly higher"
    ),
    name = NULL
  ) +

  scale_fill_manual(
    values = c(
      "Significantly lower" = col_negative,
      "Not significant" = col_ns_point,
      "Significantly higher" = col_positive
    ),
    breaks = c(
      "Significantly lower",
      "Not significant",
      "Significantly higher"
    ),
    name = NULL
  ) +

  # Larger X-axis
  scale_x_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0.01, 0.01))
  ) +

  labs(
    x = "Persistent robust signals not identified in current FDA labeling",
    y = NULL
  ) +

  coord_cartesian(
    ylim = c(0.65, 7.85),
    clip = "off"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    # Larger X-axis title and ticks
    axis.title.x = element_text(
      size = 14.0,
      face = "bold",
      margin = margin(t = 14)
    ),

    axis.text.x = element_text(
      size = 12.8,
      color = col_text
    ),

    # Larger Y-axis labels
    axis.text.y = element_text(
      size = 13.5,
      face = "bold",
      color = col_text,
      margin = margin(r = 12)
    ),

    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),

    axis.line.x = element_line(
      linewidth = 0.8,
      color = col_text
    ),

    axis.ticks.x = element_line(
      linewidth = 0.75,
      color = col_text
    ),

    panel.grid.major.x = element_line(
      color = col_grid,
      linewidth = 0.50
    ),

    panel.grid.minor = element_blank(),

    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.text = element_text(
      size = 11.2,
      color = col_text
    ),
    legend.key.width = unit(11, "mm"),
    legend.spacing.x = unit(3, "mm"),

    plot.margin = margin(
      t = 16,
      r = 14,
      b = 8,
      l = 8
    )
  ) +

  guides(
    color = guide_legend(
      override.aes = list(
        linewidth = 1.1,
        size = 4.4,
        shape = 21
      )
    ),
    fill = "none"
  )

# ------------------------------------------------------------
# Show in RStudio
# ------------------------------------------------------------
print(p)

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------
stem <- file.path(
  output_dir,
  "Figure2_domain_discordance_significance_v2"
)

ggsave(
  paste0(stem, ".png"),
  p,
  width = 190,
  height = 125,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(stem, ".tiff"),
  p,
  width = 190,
  height = 125,
  units = "mm",
  dpi = 600,
  compression = "lzw",
  bg = "white"
)

if (requireNamespace("svglite", quietly = TRUE)) {
  ggsave(
    paste0(stem, ".svg"),
    p,
    width = 190,
    height = 125,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

ggsave(
  paste0(stem, ".pdf"),
  p,
  width = 190,
  height = 125,
  units = "mm",
  device = cairo_pdf,
  bg = "white"
)

write.csv(
  df,
  paste0(stem, "_data_and_domain_tests.csv"),
  row.names = FALSE
)

cat("\nSaved Figure 2 files\n")
cat("--------------------\n")
cat(paste0(stem, ".png\n"))
cat(paste0(stem, ".tiff\n"))
cat(paste0(stem, ".pdf\n"))
if (requireNamespace("svglite", quietly = TRUE)) {
  cat(paste0(stem, ".svg\n"))
}
cat(paste0(stem, "_data_and_domain_tests.csv\n"))

message(
  "\nFigure 2 displayed in RStudio and saved to: ",
  output_dir
)
