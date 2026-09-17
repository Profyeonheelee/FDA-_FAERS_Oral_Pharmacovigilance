# Reproduction script for the associated manuscript figure.
# Set FAERS_PROJECT_ROOT to the repository root when running outside the project directory.

library(ggplot2)

# ------------------------------------------------------------
# Output folder
# ------------------------------------------------------------
project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
output_dir <- file.path(project_root, "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Nature/NPG-inspired palette
# ------------------------------------------------------------
col_explicit <- "#00A087"
col_broad    <- adjustcolor("#4DBBD5", alpha.f = 0.55)
col_notid    <- "#A23B2A"

col_text     <- "#222222"
col_muted    <- "#666666"
col_grid     <- "#E6E6E6"
col_strip    <- "#F5F5F5"
col_overall  <- "#555555"

# ------------------------------------------------------------
# Locked Step 7C clinical-concept results
# ------------------------------------------------------------
concept <- data.frame(
  Domain = c(
    "Salivary dysfunction",
    "Salivary dysfunction",
    "Salivary dysfunction",

    "Oral mucosal / tongue",
    "Oral mucosal / tongue",
    "Oral mucosal / tongue",
    "Oral mucosal / tongue",
    "Oral mucosal / tongue",

    "Taste / chemosensory",
    "Taste / chemosensory",
    "Taste / chemosensory",

    "Jaw / alveolar bone",

    "Oral infection",

    "Dental / pulpal",
    "Dental / pulpal",
    "Dental / pulpal",
    "Dental / pulpal",

    "Gingival / periodontal",
    "Gingival / periodontal",
    "Gingival / periodontal",
    "Gingival / periodontal"
  ),

  Clinical_concept = c(
    "Xerostomia",
    "Hypersalivation",
    "Aptyalism",

    "Stomatitis",
    "Oral ulceration",
    "Glossitis",
    "Glossodynia",
    "Tongue ulceration",

    "Taste disturbance",
    "Ageusia",
    "Hypogeusia",

    "Osteonecrosis of jaw",

    "Oral candidiasis",

    "Tooth discolouration",
    "Dental caries",
    "Tooth infection",
    "Root canal infection",

    "Gingival enlargement",
    "Gingival bleeding",
    "Gingivitis",
    "Periodontitis"
  ),

  review_units = c(
    100, 50, 1,
    90, 56, 20, 40, 17,
    95, 44, 15,
    16,
    43,
    19, 17, 30, 5,
    10, 34, 16, 8
  ),

  Explicit = c(
    87, 24, 0,
    71, 26, 8, 7, 2,
    68, 16, 1,
    9,
    13,
    12, 3, 2, 0,
    5, 6, 3, 0
  ),

  Broad = c(
    2, 5, 0,
    6, 17, 1, 1, 1,
    3, 1, 0,
    0,
    3,
    0, 0, 0, 0,
    0, 1, 0, 0
  ),

  Not_identified = c(
    11, 21, 1,
    13, 13, 11, 32, 14,
    24, 27, 14,
    7,
    27,
    7, 14, 28, 5,
    5, 27, 13, 8
  ),

  stringsAsFactors = FALSE
)

source_file <- file.path(
  project_root, "data", "06_publication_outputs", "figure3_clinical_concept_concordance_data.csv"
)
source_data <- read.csv(source_file, stringsAsFactors = FALSE, check.names = FALSE)
concept <- data.frame(
  Domain = source_data$Domain,
  Clinical_concept = source_data$Clinical_concept,
  review_units = source_data$review_units,
  Explicit = source_data$Explicitly_represented_n,
  Broad = source_data$Broadly_represented_n,
  Not_identified = source_data$Not_identified_n,
  stringsAsFactors = FALSE
)

# Sanity check
stopifnot(
  all(
    concept$Explicit +
      concept$Broad +
      concept$Not_identified ==
      concept$review_units
  )
)

# ------------------------------------------------------------
# Percentages
# ------------------------------------------------------------
concept$Explicit_pct <- 100 * concept$Explicit / concept$review_units
concept$Broad_pct <- 100 * concept$Broad / concept$review_units
concept$Not_identified_pct <- 100 * concept$Not_identified / concept$review_units

# ------------------------------------------------------------
# Domain ordering
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

concept$Domain <- factor(
  concept$Domain,
  levels = domain_order
)

# Order concepts within each domain from lower to higher discordance.
concept <- concept[
  order(
    concept$Domain,
    concept$Not_identified_pct,
    decreasing = c(FALSE, FALSE)
  ),
]

# Create a unique y-axis key while showing only the clinical concept.
concept$concept_key <- paste(
  concept$Domain,
  concept$Clinical_concept,
  sep = "___"
)

# Because ggplot draws factor levels bottom-to-top, reverse them.
concept$concept_key <- factor(
  concept$concept_key,
  levels = rev(concept$concept_key)
)

# ------------------------------------------------------------
# Convert to long format without tidyr dependency
# ------------------------------------------------------------
long <- rbind(
  data.frame(
    Domain = concept$Domain,
    concept_key = concept$concept_key,
    Clinical_concept = concept$Clinical_concept,
    review_units = concept$review_units,
    Status = "Explicitly represented",
    count = concept$Explicit,
    percent = concept$Explicit_pct
  ),
  data.frame(
    Domain = concept$Domain,
    concept_key = concept$concept_key,
    Clinical_concept = concept$Clinical_concept,
    review_units = concept$review_units,
    Status = "Broadly represented",
    count = concept$Broad,
    percent = concept$Broad_pct
  ),
  data.frame(
    Domain = concept$Domain,
    concept_key = concept$concept_key,
    Clinical_concept = concept$Clinical_concept,
    review_units = concept$review_units,
    Status = "Not identified",
    count = concept$Not_identified,
    percent = concept$Not_identified_pct
  )
)

long$Status <- factor(
  long$Status,
  levels = c(
    "Explicitly represented",
    "Broadly represented",
    "Not identified"
  )
)

# Text inside bars only when there is enough room.
long$segment_label <- ifelse(
  long$percent >= 9,
  sprintf("%.0f%%", long$percent),
  ""
)

# n label at the right of each bar.
n_labels <- concept
n_labels$n_label <- ifelse(
  n_labels$review_units < 10,
  paste0("n=", n_labels$review_units, "\u2020"),
  paste0("n=", n_labels$review_units)
)

# ------------------------------------------------------------
# Console output
# ------------------------------------------------------------
cat("\n")
cat("====================================================================\n")
cat("FIGURE 3 - CLINICAL-CONCEPT-LEVEL FDA LABEL CONCORDANCE\n")
cat("====================================================================\n")

console_df <- concept[
  ,
  c(
    "Domain",
    "Clinical_concept",
    "review_units",
    "Explicit",
    "Broad",
    "Not_identified",
    "Explicit_pct",
    "Broad_pct",
    "Not_identified_pct"
  )
]

console_df$Explicit_pct <- round(console_df$Explicit_pct, 1)
console_df$Broad_pct <- round(console_df$Broad_pct, 1)
console_df$Not_identified_pct <- round(
  console_df$Not_identified_pct,
  1
)

print(console_df, row.names = FALSE)

cat("\nOverall FDA-label concordance\n")
cat("-----------------------------\n")
cat("Explicitly represented: 363/726 (50.0%)\n")
cat("Broadly represented   :  41/726 (5.6%)\n")
cat("Any representation    : 404/726 (55.6%)\n")
cat("Not identified        : 322/726 (44.4%)\n")
cat("Unresolved            :   0/726 (0.0%)\n")

cat("\nSmall-denominator concepts marked with dagger: n < 10.\n")
cat("Domain-level inferential tests are shown in Figure 2, not repeated here.\n")
cat("====================================================================\n\n")

# ------------------------------------------------------------
# Plot
# ------------------------------------------------------------
p <- ggplot(
  long,
  aes(
    x = percent,
    y = concept_key,
    fill = Status
  )
) +

  # 100% stacked bars
  geom_col(
    width = 0.72,
    color = "white",
    linewidth = 0.35
  ) +

  # Percentage labels inside sufficiently large segments
  geom_text(
    aes(label = segment_label),
    position = position_stack(vjust = 0.5),
    family = "sans",
    fontface = "bold",
    size = 3.2,
    color = "white"
  ) +

  # Review-unit count at right
  geom_text(
    data = n_labels,
    aes(
      x = 103,
      y = concept_key,
      label = n_label
    ),
    inherit.aes = FALSE,
    family = "sans",
    fontface = "bold",
    size = 3.25,
    hjust = 0,
    color = col_text
  ) +

  # Overall reference at 44.4%.
  # Keep only the dark-grey guide line; the value is stated once in the
  # caption/legend rather than repeated in every facet.
  geom_vline(
    xintercept = 44.4,
    color = col_overall,
    linewidth = 0.75,
    linetype = "22",
    alpha = 0.75
  ) +

  # Facet by domain
  facet_grid(
    Domain ~ .,
    scales = "free_y",
    space = "free_y",
    switch = "y"
  ) +

  scale_fill_manual(
    values = c(
      "Explicitly represented" = col_explicit,
      "Broadly represented" = col_broad,
      "Not identified" = col_notid
    ),
    name = NULL
  ) +

  scale_x_continuous(
    limits = c(0, 110),
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%"),
    expand = c(0, 0)
  ) +

  scale_y_discrete(
    labels = function(x) sub("^.*___", "", x)
  ) +

  labs(
    x = "Distribution of current FDA-label representation",
    y = NULL,
    caption = "Dashed dark-grey line indicates the overall Not identified proportion (44.4%)."
  ) +

  coord_cartesian(
    clip = "off"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    # Large clinical-concept labels
    axis.text.y = element_text(
      size = 11.5,
      color = col_text,
      margin = margin(r = 8)
    ),

    # Large x-axis
    axis.title.x = element_text(
      size = 13.5,
      face = "bold",
      margin = margin(t = 12)
    ),

    axis.text.x = element_text(
      size = 11.5,
      color = col_text
    ),

    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),

    axis.line.x = element_line(
      linewidth = 0.75,
      color = col_text
    ),

    axis.ticks.x = element_line(
      linewidth = 0.70,
      color = col_text
    ),

    panel.grid.major.x = element_line(
      color = col_grid,
      linewidth = 0.45
    ),

    panel.grid.minor = element_blank(),

    # Domain strips
    strip.placement = "outside",
    strip.background = element_rect(
      fill = col_strip,
      color = NA
    ),

    strip.text.y.left = element_text(
      angle = 0,
      face = "bold",
      size = 10.5,
      color = col_text,
      hjust = 1,
      margin = margin(r = 8)
    ),

    # Legend
    legend.position = "top",
    legend.direction = "horizontal",
    legend.justification = "left",
    legend.text = element_text(
      size = 11.2,
      color = col_text
    ),
    legend.key.width = unit(8, "mm"),
    legend.spacing.x = unit(3, "mm"),

    panel.spacing.y = unit(2.5, "mm"),

    plot.caption = element_text(
      family = "sans",
      size = 9.6,
      color = col_overall,
      hjust = 0.5,
      margin = margin(t = 8)
    ),

    plot.margin = margin(
      t = 5,
      r = 28,
      b = 10,
      l = 5
    )
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
  "Figure3_clinical_concept_label_concordance_v2_soft"
)

ggsave(
  paste0(stem, ".png"),
  p,
  width = 190,
  height = 185,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(stem, ".tiff"),
  p,
  width = 190,
  height = 185,
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
    height = 185,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

ggsave(
  paste0(stem, ".pdf"),
  p,
  width = 190,
  height = 185,
  units = "mm",
  device = cairo_pdf,
  bg = "white"
)

write.csv(
  concept,
  paste0(stem, "_concept_data.csv"),
  row.names = FALSE
)

cat("\nSaved Figure 3 files\n")
cat("--------------------\n")
cat(paste0(stem, ".png\n"))
cat(paste0(stem, ".tiff\n"))
cat(paste0(stem, ".pdf\n"))

if (requireNamespace("svglite", quietly = TRUE)) {
  cat(paste0(stem, ".svg\n"))
}

cat(paste0(stem, "_concept_data.csv\n"))

message(
  "\nFigure 3 displayed in RStudio and saved to: ",
  output_dir
)
