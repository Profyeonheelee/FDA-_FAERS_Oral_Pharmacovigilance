# Standalone reproduction script for Supplementary Figure S1.
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
project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
input_file <- file.path(
  project_root,
  "step6_primary_robust_signals.csv"
)

output_dir <- file.path(project_root, "figures")

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

df <- read.csv(
  input_file,
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

df$Domain <- factor(
  df$Domain,
  levels = domain_order
)

# ------------------------------------------------------------
# Persistent signal indicator
# ------------------------------------------------------------
to_logical <- function(x) {
  tolower(trimws(as.character(x))) %in%
    c("true", "1", "yes")
}

df$Persistent <- to_logical(
  df$robust_and_temporally_repeated
)

# Use the locked first-to-last reporting span already present
# in the Step 6 primary output.
df$Reporting_span <- as.numeric(
  df$first_to_last_year_span
)

# ------------------------------------------------------------
# Wilson 95% CI function
# ------------------------------------------------------------
wilson_ci <- function(x, n, z = 1.96) {

  p <- x / n

  denominator <- 1 + z^2 / n

  center <- (
    p + z^2 / (2 * n)
  ) / denominator

  half_width <- (
    z *
      sqrt(
        p * (1 - p) / n +
          z^2 / (4 * n^2)
      )
  ) / denominator

  c(
    lower = center - half_width,
    upper = center + half_width
  )
}

# ------------------------------------------------------------
# Panel a source data
# ------------------------------------------------------------
summary_a <- do.call(
  rbind,
  lapply(
    domain_order,
    function(d) {

      x <- df$Persistent[df$Domain == d]

      robust_n <- length(x)
      persistent_n <- sum(x)

      ci <- wilson_ci(
        persistent_n,
        robust_n
      )

      data.frame(
        Domain = d,
        Robust = robust_n,
        Persistent = persistent_n,
        Percent = 100 * persistent_n / robust_n,
        Lower = 100 * ci["lower"],
        Upper = 100 * ci["upper"]
      )
    }
  )
)

summary_a$Domain <- factor(
  summary_a$Domain,
  levels = rev(domain_order)
)

summary_a$Count_label <- paste0(
  summary_a$Persistent,
  "/",
  summary_a$Robust
)

overall_robust <- nrow(df)
overall_persistent <- sum(df$Persistent)
overall_pct <- (
  100 * overall_persistent / overall_robust
)

# ------------------------------------------------------------
# Panel b source data
# ------------------------------------------------------------
persistent_df <- df[
  df$Persistent,
]

persistent_df$Domain <- factor(
  persistent_df$Domain,
  levels = domain_order
)

summary_b <- do.call(
  rbind,
  lapply(
    domain_order,
    function(d) {

      x <- persistent_df$Reporting_span[
        persistent_df$Domain == d
      ]

      data.frame(
        Domain = d,
        n = length(x),
        Median = median(x, na.rm = TRUE),
        Q1 = unname(
          quantile(
            x,
            0.25,
            na.rm = TRUE
          )
        ),
        Q3 = unname(
          quantile(
            x,
            0.75,
            na.rm = TRUE
          )
        )
      )
    }
  )
)

# ------------------------------------------------------------
# Colors
# Panel a stays restrained navy/grey.
# Panel b uses a muted Nature-style 7-domain palette.
# ------------------------------------------------------------
col_point <- "#3C5488"
col_overall <- "#555555"
col_text <- "#222222"
col_muted <- "#666666"
col_grid <- "#E7E7E7"

domain_colors <- c(
  "Salivary dysfunction"     = "#5B6F95",  # muted navy
  "Oral mucosal / tongue"   = "#8FB6C8",  # dusty light blue
  "Taste / chemosensory"    = "#8C7A6B",  # taupe brown
  "Jaw / alveolar bone"     = "#B7A27A",  # warm sand
  "Oral infection"          = "#9D6B53",  # muted terracotta
  "Dental / pulpal"         = "#7F8C8D",  # slate grey
  "Gingival / periodontal"  = "#6E8576"   # muted sage
)

# ------------------------------------------------------------
# Console output
# ------------------------------------------------------------
cat("\n")
cat("============================================================\n")
cat("SUPPLEMENTARY FIGURE S1 - TEMPORAL PERSISTENCE\n")
cat("============================================================\n")

cat(
  "Primary robust signals:",
  overall_robust,
  "\n"
)

cat(
  "Persistent robust signals:",
  overall_persistent,
  sprintf(
    "(%.1f%%)\n",
    overall_pct
  )
)

cat(
  "Robust but not persistent:",
  overall_robust - overall_persistent,
  "\n\n"
)

cat("Panel a: persistence by domain\n")
print(
  summary_a[
    rev(seq_len(nrow(summary_a))),
  ],
  row.names = FALSE
)

cat("\nPanel b: reporting-span summary\n")
print(
  summary_b,
  row.names = FALSE
)

cat("============================================================\n\n")

# ------------------------------------------------------------
# Panel a
# ------------------------------------------------------------
p_a <- ggplot(
  summary_a,
  aes(
    x = Percent,
    y = Domain
  )
) +

  # Overall persistence reference
  geom_vline(
    xintercept = overall_pct,
    linetype = "22",
    linewidth = 0.75,
    color = col_overall,
    alpha = 0.8
  ) +

  # Wilson 95% confidence interval
  # Drawn explicitly as a horizontal segment with vertical end caps.
  # This avoids odd rendering when a domain has a small denominator
  # and therefore a wide confidence interval (e.g., Jaw / alveolar bone).
  geom_segment(
    aes(
      x = Lower,
      xend = Upper,
      y = Domain,
      yend = Domain
    ),
    linewidth = 0.95,
    color = col_point,
    lineend = "round"
  ) +

  geom_segment(
    aes(
      x = Lower,
      xend = Lower,
      y = as.numeric(Domain) - 0.09,
      yend = as.numeric(Domain) + 0.09
    ),
    linewidth = 0.85,
    color = col_point
  ) +

  geom_segment(
    aes(
      x = Upper,
      xend = Upper,
      y = as.numeric(Domain) - 0.09,
      yend = as.numeric(Domain) + 0.09
    ),
    linewidth = 0.85,
    color = col_point
  ) +

  # Point estimate
  geom_point(
    shape = 21,
    size = 4.3,
    stroke = 0.9,
    fill = col_point,
    color = "white"
  ) +

  # n/N labels
  geom_text(
    aes(
      x = 101.5,
      label = Count_label
    ),
    hjust = 0,
    family = "sans",
    fontface = "bold",
    size = 3.55,
    color = col_text
  ) +

  scale_x_continuous(
    limits = c(70, 106),
    breaks = c(
      70, 75, 80, 85, 90, 95, 100
    ),
    labels = function(x) {
      paste0(x, "%")
    },
    expand = c(0, 0)
  ) +

  coord_cartesian(
    clip = "off"
  ) +

  labs(
    x = "Robust signals meeting temporal-repetition criterion",
    y = NULL,
    tag = "a"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    axis.text.y = element_text(
      size = 11.2,
      color = col_text,
      margin = margin(r = 7)
    ),

    axis.text.x = element_text(
      size = 10.8,
      color = col_text
    ),

    axis.title.x = element_text(
      size = 12.2,
      face = "bold",
      margin = margin(t = 10)
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
      t = 5,
      r = 32,
      b = 5,
      l = 5
    )
  )

# ------------------------------------------------------------
# Panel b
# ------------------------------------------------------------
p_b <- ggplot(
  persistent_df,
  aes(
    x = Domain,
    y = Reporting_span
  )
) +

  geom_boxplot(
    aes(
      fill = Domain,
      color = Domain
    ),
    width = 0.60,
    outlier.shape = NA,
    linewidth = 0.85,
    alpha = 0.42
  ) +

  # Light raw-data points retain the same domain hue.
  geom_jitter(
    aes(
      color = Domain
    ),
    width = 0.14,
    height = 0,
    shape = 16,
    size = 1.15,
    alpha = 0.22,
    show.legend = FALSE
  ) +

  # Median point uses the same domain color with a white border.
  stat_summary(
    aes(
      fill = Domain
    ),
    fun = median,
    geom = "point",
    shape = 21,
    size = 3.4,
    stroke = 0.9,
    color = "white",
    show.legend = FALSE
  ) +

  scale_fill_manual(
    values = domain_colors,
    guide = "none"
  ) +

  scale_color_manual(
    values = domain_colors,
    guide = "none"
  ) +

  scale_y_continuous(
    breaks = seq(
      0,
      25,
      5
    ),
    expand = expansion(
      mult = c(0.02, 0.06)
    )
  ) +

  labs(
    x = NULL,
    y = "First-to-last reporting span, years",
    tag = "b"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    axis.text.x = element_text(
      angle = 32,
      hjust = 1,
      size = 10.4,
      color = col_text
    ),

    axis.text.y = element_text(
      size = 10.8,
      color = col_text
    ),

    axis.title.y = element_text(
      size = 12.2,
      face = "bold",
      margin = margin(r = 10)
    ),

    panel.grid.major.y = element_line(
      color = col_grid,
      linewidth = 0.45
    ),

    panel.grid.minor = element_blank(),

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

# ------------------------------------------------------------
# Combine panels
# ------------------------------------------------------------
fig_s1 <- p_a + p_b +
  plot_layout(
    widths = c(1.05, 1.20)
  )

# ------------------------------------------------------------
# Display figure in R / RStudio
# ------------------------------------------------------------
print(fig_s1)

# ------------------------------------------------------------
# Save source data
# ------------------------------------------------------------
write.csv(
  summary_a,
  file.path(
    output_dir,
    "Supplementary_Figure_S1_panel_a_data.csv"
  ),
  row.names = FALSE
)

write.csv(
  summary_b,
  file.path(
    output_dir,
    "Supplementary_Figure_S1_panel_b_summary.csv"
  ),
  row.names = FALSE
)

# ------------------------------------------------------------
# Save figure
# ------------------------------------------------------------
stem <- file.path(
  output_dir,
  "Supplementary_Figure_S1_temporal_persistence_v3_muted_domain_colors"
)

ggsave(
  paste0(
    stem,
    ".png"
  ),
  fig_s1,
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
  fig_s1,
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
  fig_s1,
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
    fig_s1,
    width = 205,
    height = 118,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

cat("\nSaved Supplementary Figure S1 files to:\n")
cat(output_dir, "\n")

# Re-display after saving so the completed figure remains visible
# in the RStudio Plots pane when the script finishes.
print(fig_s1)
