# Standalone reproduction script for Supplementary Figure S4.
# All required input files are resolved from the repository root.

library(ggplot2)

library(patchwork)

library(sandwich)

# ------------------------------------------------------------
# Show directly in RStudio
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
# Locate dedicated model-input CSV
# ------------------------------------------------------------
input_name <- "Supplementary_Figure_S4_model_input.csv"

find_model_input <- function() {

  direct_candidates <- unique(
    c(
      file.path(analysis_dir, input_name),
      file.path(getwd(), input_name),
      file.path(data_root, input_name)
    )
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
    data_root,
    pattern = paste0(
      "^",
      gsub("\\.", "\\\\.", input_name),
      "$"
    ),
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(hits) >= 1) {
    return(
      normalizePath(
        hits[1],
        winslash = "/",
        mustWork = TRUE
      )
    )
  }

  if (interactive()) {
    message(
      "\nCould not find ",
      input_name,
      " automatically.\n",
      "Please select the downloaded CSV in the file chooser."
    )

    chosen <- file.choose()

    return(
      normalizePath(
        chosen,
        winslash = "/",
        mustWork = TRUE
      )
    )
  }

  stop(
    paste0(
      "Could not find ",
      input_name,
      ".\n",
      "Place it in:\n",
      analysis_dir
    )
  )
}

input_file <- find_model_input()

cat("\nUsing model input:\n")
cat(input_file, "\n\n")

# ------------------------------------------------------------
# Read dedicated 726-row review-unit dataset
# ------------------------------------------------------------
df <- read.csv(
  input_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_columns <- c(
  "canonical_pharmacovigilance_ingredient",
  "Domain",
  "Clinical_concept",
  "final_label_status",
  "discordant_binary",
  "max_EB05",
  "max_ROR",
  "max_a",
  "earliest_signal_year",
  "latest_signal_year"
)

missing_columns <- setdiff(
  required_columns,
  names(df)
)

if (length(missing_columns) > 0) {
  stop(
    paste0(
      "The selected CSV is not the dedicated Figure S4 model-input file.\n\n",
      "Missing columns:\n",
      paste(
        missing_columns,
        collapse = ", "
      )
    )
  )
}

stopifnot(
  nrow(df) == 726
)

# ------------------------------------------------------------
# Model variables
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

df$Domain <- relevel(
  df$Domain,
  ref = "Salivary dysfunction"
)

df$discordant <- as.integer(
  df$discordant_binary
)

df$max_EB05 <- as.numeric(
  df$max_EB05
)

df$max_a <- as.numeric(
  df$max_a
)

df$signal_duration_years <- (
  as.numeric(
    df$latest_signal_year
  ) -
    as.numeric(
      df$earliest_signal_year
    ) +
    1
)

# Scaling for interpretable ORs
df$log2_EB05 <- log2(
  df$max_EB05
)

df$log2_a <- log2(
  df$max_a
)

df$duration_5y <- (
  df$signal_duration_years /
    5
)

analysis_df <- df[
  complete.cases(
    df[
      ,
      c(
        "discordant",
        "Domain",
        "log2_EB05",
        "log2_a",
        "duration_5y",
        "canonical_pharmacovigilance_ingredient"
      )
    ]
  ),
]

cat(
  "Model analysis units: ",
  nrow(analysis_df),
  " / 726\n",
  sep = ""
)

cat(
  "Ingredient clusters: ",
  length(
    unique(
      analysis_df$canonical_pharmacovigilance_ingredient
    )
  ),
  "\n\n",
  sep = ""
)

# ------------------------------------------------------------
# Exploratory logistic regression
# ------------------------------------------------------------
fit <- glm(
  discordant ~
    Domain +
    log2_EB05 +
    log2_a +
    duration_5y,
  data = analysis_df,
  family = binomial(
    link = "logit"
  )
)

# Ingredient-clustered sandwich covariance
V_cluster <- sandwich::vcovCL(
  fit,
  cluster = analysis_df$canonical_pharmacovigilance_ingredient,
  type = "HC0"
)

beta <- coef(fit)
se_cluster <- sqrt(
  diag(
    V_cluster
  )
)

z_value <- beta / se_cluster

p_value <- 2 * pnorm(
  abs(
    z_value
  ),
  lower.tail = FALSE
)

ci_low <- beta - 1.96 * se_cluster
ci_high <- beta + 1.96 * se_cluster

coef_df <- data.frame(
  term = names(beta),
  beta = as.numeric(beta),
  SE = as.numeric(se_cluster),
  z = as.numeric(z_value),
  P = as.numeric(p_value),
  OR = exp(beta),
  lower95 = exp(ci_low),
  upper95 = exp(ci_high),
  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# Global clustered Wald test for domain
# ------------------------------------------------------------
domain_terms <- grep(
  "^Domain",
  names(beta),
  value = TRUE
)

b_dom <- beta[
  domain_terms
]

V_dom <- V_cluster[
  domain_terms,
  domain_terms,
  drop = FALSE
]

wald_domain <- as.numeric(
  t(b_dom) %*%
    solve(V_dom) %*%
    b_dom
)

df_domain <- length(
  domain_terms
)

p_domain <- pchisq(
  wald_domain,
  df = df_domain,
  lower.tail = FALSE
)

# ------------------------------------------------------------
# Formatting helper
# ------------------------------------------------------------
format_p <- function(p) {

  if (is.na(p)) {
    return("")
  }

  if (p < 0.001) {
    return(
      format(
        p,
        scientific = TRUE,
        digits = 2
      )
    )
  }

  sprintf(
    "%.3f",
    p
  )
}

# ------------------------------------------------------------
# Panel a: domains
# ------------------------------------------------------------
domain_map <- c(
  "DomainOral mucosal / tongue" = "Oral mucosal / tongue",
  "DomainTaste / chemosensory" = "Taste / chemosensory",
  "DomainJaw / alveolar bone" = "Jaw / alveolar bone",
  "DomainOral infection" = "Oral infection",
  "DomainDental / pulpal" = "Dental / pulpal",
  "DomainGingival / periodontal" = "Gingival / periodontal"
)

panel_a_df <- coef_df[
  coef_df$term %in%
    names(domain_map),
]

panel_a_df$Label <- unname(
  domain_map[
    panel_a_df$term
  ]
)

panel_a_df$Label <- factor(
  panel_a_df$Label,
  levels = rev(
    domain_order[
      domain_order !=
        "Salivary dysfunction"
    ]
  )
)

panel_a_df$OR_label <- paste0(
  sprintf(
    "%.2f",
    panel_a_df$OR
  ),
  " (",
  sprintf(
    "%.2f",
    panel_a_df$lower95
  ),
  "–",
  sprintf(
    "%.2f",
    panel_a_df$upper95
  ),
  ")"
)

panel_a_df$P_label <- paste0(
  "P = ",
  vapply(
    panel_a_df$P,
    format_p,
    character(1)
  )
)

panel_a_df$Stats_label <- paste0(
  panel_a_df$OR_label,
  "\n",
  panel_a_df$P_label
)

# ------------------------------------------------------------
# Panel b: continuous predictors
# ------------------------------------------------------------
continuous_map <- c(
  "log2_EB05" = "Max EB05\n(per doubling)",
  "log2_a" = "Co-report count, a\n(per doubling)",
  "duration_5y" = "Reporting span\n(per 5 years)"
)

panel_b_df <- coef_df[
  coef_df$term %in%
    names(continuous_map),
]

panel_b_df$Label <- unname(
  continuous_map[
    panel_b_df$term
  ]
)

panel_b_df$Label <- factor(
  panel_b_df$Label,
  levels = rev(
    unname(
      continuous_map
    )
  )
)

panel_b_df$OR_label <- paste0(
  sprintf(
    "%.2f",
    panel_b_df$OR
  ),
  " (",
  sprintf(
    "%.2f",
    panel_b_df$lower95
  ),
  "–",
  sprintf(
    "%.2f",
    panel_b_df$upper95
  ),
  ")"
)

panel_b_df$P_label <- paste0(
  "P = ",
  vapply(
    panel_b_df$P,
    format_p,
    character(1)
  )
)

# ------------------------------------------------------------
# Console results
# ------------------------------------------------------------
cat("\n")
cat("============================================================\n")
cat("SUPPLEMENTARY FIGURE S4 - EXPLORATORY CLUSTERED MODEL\n")
cat("============================================================\n")

print(
  coef_df[
    coef_df$term != "(Intercept)",
    c(
      "term",
      "OR",
      "lower95",
      "upper95",
      "P"
    )
  ],
  row.names = FALSE
)

cat("\nReference domain: Salivary dysfunction\n")

cat(
  "Global domain Wald chi-square(",
  df_domain,
  ") = ",
  sprintf(
    "%.2f",
    wald_domain
  ),
  ", P = ",
  format_p(
    p_domain
  ),
  "\n",
  sep = ""
)

cat("============================================================\n\n")

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------
col_domain <- "#8C6F56"
col_domain_border <- "#5F4C3D"

col_continuous <- "#2F4F7F"
col_cont_border <- "#283B63"

col_ci <- "#555555"
col_ref <- "#777777"
col_text <- "#222222"
col_muted <- "#666666"
col_grid <- "#E7E7E7"

# ------------------------------------------------------------
# Panel a plot
# ------------------------------------------------------------
max_a_ci <- max(
  panel_a_df$upper95
)

p_a <- ggplot(
  panel_a_df,
  aes(
    x = OR,
    y = Label
  )
) +

  geom_vline(
    xintercept = 1,
    linetype = "22",
    linewidth = 0.75,
    color = col_ref
  ) +

  geom_segment(
    aes(
      x = lower95,
      xend = upper95,
      y = Label,
      yend = Label
    ),
    linewidth = 1.05,
    color = col_ci,
    lineend = "round"
  ) +

  geom_point(
    shape = 21,
    size = 5.8,
    stroke = 0.85,
    fill = col_domain,
    color = col_domain_border
  ) +

  # Two-line annotation avoids overlap:
  # first line = adjusted OR (95% CI), second line = P value.
  geom_text(
    aes(
      x = 65,
      label = Stats_label
    ),
    family = "sans",
    size = 3.25,
    hjust = 0,
    lineheight = 1.18,
    color = col_text
  ) +

  scale_x_log10(
    limits = c(
      0.5,
      150
    ),
    breaks = c(
      0.5,
      1,
      2,
      5,
      10,
      20,
      50
    ),
    labels = c(
      "0.5",
      "1",
      "2",
      "5",
      "10",
      "20",
      "50"
    ),
    expand = c(
      0,
      0
    )
  ) +

  coord_cartesian(
    clip = "off"
  ) +

  labs(
    x = "Adjusted odds ratio for label discordance",
    y = NULL,
    tag = "a"
  ) +

  annotate(
    "text",
    x = 0.52,
    y = Inf,
    label = paste0(
      "Reference: Salivary dysfunction\n",
      "Global domain test: Wald χ²(",
      df_domain,
      ") = ",
      sprintf(
        "%.2f",
        wald_domain
      ),
      ", P = ",
      format_p(
        p_domain
      )
    ),
    family = "sans",
    size = 3.15,
    color = col_muted,
    hjust = 0,
    vjust = 1.2
  ) +

  annotate(
    "text",
    x = 65,
    y = Inf,
    label = "Adjusted OR (95% CI)\nP value",
    family = "sans",
    fontface = "bold",
    size = 3.05,
    color = col_muted,
    hjust = 0,
    vjust = 1.15,
    lineheight = 1.15
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    axis.text.y = element_text(
      size = 10.8,
      color = col_text,
      margin = margin(
        r = 8
      )
    ),

    axis.text.x = element_text(
      size = 10.5,
      color = col_text
    ),

    axis.title.x = element_text(
      size = 12.0,
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
      t = 25,
      r = 38,
      b = 5,
      l = 5
    )
  )

# ------------------------------------------------------------
# Panel b plot
# ------------------------------------------------------------
p_b <- ggplot(
  panel_b_df,
  aes(
    x = OR,
    y = Label
  )
) +

  geom_vline(
    xintercept = 1,
    linetype = "22",
    linewidth = 0.75,
    color = col_ref
  ) +

  geom_segment(
    aes(
      x = lower95,
      xend = upper95,
      y = Label,
      yend = Label
    ),
    linewidth = 1.05,
    color = col_ci,
    lineend = "round"
  ) +

  geom_point(
    shape = 21,
    size = 5.8,
    stroke = 0.85,
    fill = col_continuous,
    color = col_cont_border
  ) +

  geom_text(
    aes(
      x = 1.55,
      label = OR_label
    ),
    family = "sans",
    size = 3.35,
    hjust = 0,
    color = col_text
  ) +

  geom_text(
    aes(
      x = 2.45,
      label = P_label
    ),
    family = "sans",
    fontface = "bold",
    size = 3.25,
    hjust = 0,
    color = col_cont_border
  ) +

  scale_x_log10(
    limits = c(
      0.45,
      3.5
    ),
    breaks = c(
      0.5,
      0.75,
      1,
      1.5,
      2,
      3
    ),
    labels = c(
      "0.5",
      "0.75",
      "1",
      "1.5",
      "2",
      "3"
    ),
    expand = c(
      0,
      0
    )
  ) +

  coord_cartesian(
    clip = "off"
  ) +

  labs(
    x = "Adjusted odds ratio for label discordance",
    y = NULL,
    tag = "b"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    axis.text.y = element_text(
      size = 10.8,
      color = col_text,
      lineheight = 0.95,
      margin = margin(
        r = 8
      )
    ),

    axis.text.x = element_text(
      size = 10.5,
      color = col_text
    ),

    axis.title.x = element_text(
      size = 12.0,
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
      t = 25,
      r = 58,
      b = 5,
      l = 5
    )
  )

# ------------------------------------------------------------
# Combine
# ------------------------------------------------------------
fig_s4 <- p_a + p_b +
  plot_layout(
    widths = c(
      1.25,
      0.95
    )
  )

# Display in RStudio
print(
  fig_s4
)

# ------------------------------------------------------------
# Save outputs
# ------------------------------------------------------------
write.csv(
  coef_df,
  file.path(
    output_dir,
    "Supplementary_Figure_S4_clustered_model_coefficients.csv"
  ),
  row.names = FALSE
)

stem <- file.path(
  output_dir,
  "Supplementary_Figure_S4_exploratory_clustered_logistic_model_v3_two_line_stats"
)

ggsave(
  paste0(stem, ".png"),
  fig_s4,
  width = 205,
  height = 112,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(stem, ".tiff"),
  fig_s4,
  width = 205,
  height = 112,
  units = "mm",
  dpi = 600,
  compression = "lzw",
  bg = "white"
)

ggsave(
  paste0(stem, ".pdf"),
  fig_s4,
  width = 205,
  height = 112,
  units = "mm",
  device = cairo_pdf,
  bg = "white"
)

if (requireNamespace("svglite", quietly = TRUE)) {

  ggsave(
    paste0(stem, ".svg"),
    fig_s4,
    width = 205,
    height = 112,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

cat("\nSaved Supplementary Figure S4 files to:\n")
cat(output_dir, "\n")

# Keep final figure visible.
print(
  fig_s4
)
