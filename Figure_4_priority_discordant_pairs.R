# Reproduction script for the associated manuscript figure.
# Set FAERS_PROJECT_ROOT to the repository root when running outside the project directory.

library(ggplot2)
library(grid)
library(ggtext)

# ------------------------------------------------------------
# Output folder
# ------------------------------------------------------------
project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
output_dir <- file.path(project_root, "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Nature/NPG-inspired palette
# ------------------------------------------------------------
col_point  <- "#A23B2A"   # dark red-brown: signal-label discordant
col_ci     <- "#4A4A4A"
col_ref    <- "#8491B4"
col_text   <- "#222222"
col_muted  <- "#666666"
col_grid   <- "#E7E7E7"
col_strip  <- "#F4F4F4"

# ------------------------------------------------------------
# Final display dataset
# Two selected pairs per domain
# ------------------------------------------------------------
df <- data.frame(
  Domain = c(
    "Salivary dysfunction",
    "Salivary dysfunction",

    "Oral mucosal / tongue",
    "Oral mucosal / tongue",

    "Taste / chemosensory",
    "Taste / chemosensory",

    "Jaw / alveolar bone",
    "Jaw / alveolar bone",

    "Oral infection",
    "Oral infection",

    "Dental / pulpal",
    "Dental / pulpal",

    "Gingival / periodontal",
    "Gingival / periodontal"
  ),

  Drug = c(
    "Donepezil",
    "Gadobutrol",

    "Chlorhexidine",
    "Leflunomide",

    "Vismodegib",
    "Sonidegib",

    "Radium Ra-223 dichloride",
    "Fulvestrant",

    "Zidovudine",
    "Cisplatin",

    "Pamidronate",
    "Alendronate",

    "Pamidronate",
    "Alteplase"
  ),

  Clinical_concept = c(
    "Hypersalivation",
    "Hypersalivation",

    "Glossodynia",
    "Glossodynia",

    "Hypogeusia",
    "Ageusia",

    "Osteonecrosis of jaw",
    "Osteonecrosis of jaw",

    "Oral candidiasis",
    "Oral candidiasis",

    "Dental caries",
    "Dental caries",

    "Periodontitis",
    "Gingival bleeding"
  ),

  MedDRA_PT = c(
    "Salivary hypersecretion",
    "Salivary hypersecretion",

    "Glossodynia",
    "Glossodynia",

    "Hypogeusia",
    "Ageusia",

    "Osteonecrosis of jaw",
    "Osteonecrosis of jaw",

    "Oral candidiasis",
    "Oral candidiasis",

    "Dental caries",
    "Dental caries",

    "Periodontitis",
    "Gingival bleeding"
  ),

  a = c(
    67, 22,
    144, 331,
    48, 60,
    74, 123,
    27, 73,
    169, 991,
    78, 1037
  ),

  ROR = c(
    15.9311888176,
    9.1829085078,

    67.1023619681,
    22.5708407424,

    62.0851947003,
    37.4693398023,

    13.4051001583,
    8.7304007793,

    15.0034368791,
    6.0847151908,

    87.7397530887,
    67.3669980432,

    206.5885259787,
    130.5046765933
  ),

  ROR_lower95 = c(
    12.5172361646,
    6.0381030641,

    56.6694027479,
    20.2242811568,

    46.5831293209,
    28.9215514823,

    10.6508578146,
    7.3062370406,

    10.2669796322,
    4.8321499843,

    75.1163598582,
    63.0482652078,

    164.4158912947,
    122.2161869218
  ),

  ROR_upper95 = c(
    20.2762633704,
    13.9656126712,

    79.4560514734,
    25.1896642393,

    82.7460811923,
    48.5434339882,

    16.8715716032,
    10.4321687545,

    21.9249600417,
    7.6619639443,

    102.4845225008,
    71.9815590547,

    259.5784308315,
    139.3552772483
  ),

  IC025 = c(
    3.4198095422,
    2.2364458308,

    5.4160835743,
    4.2180759465,

    4.7450767258,
    4.3693836350,

    3.2208552407,
    2.7642842828,

    2.9248558730,
    2.1570731344,

    5.8033572431,
    5.7466662138,

    6.0715385298,
    6.6272411108
  ),

  EB05 = c(
    12.5541919024,
    6.0396721997,

    52.8320020802,
    19.7642205879,

    43.0859402712,
    27.5436466990,

    10.6752455545,
    7.3577886290,

    10.2226971461,
    4.8625515871,

    70.1218687887,
    56.1440722738,

    135.9996389646,
    105.3545873709
  ),

  q = c(
    3.2398794277e-53,
    4.8098511167e-13,

    4.1664317444e-199,
    7.3973796490e-308,

    3.0892705823e-65,
    1.6912077273e-68,

    1.4930783083e-53,
    2.9055451798e-68,

    4.8825059316e-21,
    5.9439413242e-31,

    2.4883329146e-253,
    0,

    1.1289108431e-145,
    0
  ),

  reporting_years = c(
    13, 12,
    15, 12,
    13, 7,
    12, 15,
    14, 20,
    11, 21,
    11, 16
  ),

  stringsAsFactors = FALSE
)

source_file <- file.path(
  project_root, "data", "06_publication_outputs", "figure4_priority_forest_data.csv"
)
source_data <- read.csv(source_file, stringsAsFactors = FALSE, check.names = FALSE)
drug_labels <- c(
  "DONEPEZIL" = "Donepezil", "GADOBUTROL" = "Gadobutrol",
  "CHLORHEXIDINE" = "Chlorhexidine", "LEFLUNOMIDE" = "Leflunomide",
  "VISMODEGIB" = "Vismodegib", "SONIDEGIB" = "Sonidegib",
  "RADIUM RA-223 DICHLORIDE" = "Radium Ra-223 dichloride",
  "FULVESTRANT" = "Fulvestrant", "ZIDOVUDINE" = "Zidovudine",
  "CISPLATIN" = "Cisplatin", "PAMIDRONATE" = "Pamidronate",
  "ALENDRONATE" = "Alendronate", "ALTEPLASE" = "Alteplase"
)
df <- data.frame(
  Domain = source_data$Domain,
  Drug = unname(drug_labels[source_data$canonical_pharmacovigilance_ingredient]),
  Clinical_concept = source_data$Clinical_concept,
  MedDRA_PT = source_data$MedDRA_PT,
  a = source_data$a_co_reports,
  ROR = source_data$ROR,
  ROR_lower95 = source_data$ROR_lower95,
  ROR_upper95 = source_data$ROR_upper95,
  IC025 = source_data$IC025,
  EB05 = source_data$EB05,
  q = source_data$BH_FDR_q,
  reporting_years = source_data$distinct_reporting_years,
  stringsAsFactors = FALSE
)
stopifnot(nrow(df) == 14)
stopifnot(!any(is.na(df$Drug)))

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

# Within each domain, place the higher EB05 first.
df <- df[
  order(
    df$Domain,
    -df$EB05
  ),
]

# ------------------------------------------------------------
# Display labels
# ------------------------------------------------------------
df$pair_label <- paste0(
  "**", df$Drug, "**",
  "<br>",
  df$Clinical_concept
)

# Unique factor key so repeated concepts/drugs are handled safely.
df$pair_key <- paste0(
  as.character(df$Domain),
  "___",
  df$pair_label
)

df$pair_key <- factor(
  df$pair_key,
  levels = rev(df$pair_key)
)

# ------------------------------------------------------------
# Publication-style q-value formatting
# ------------------------------------------------------------
superscript_number <- function(x) {
  chars <- strsplit(as.character(x), "")[[1]]

  map <- c(
    "0" = "\u2070",
    "1" = "\u00B9",
    "2" = "\u00B2",
    "3" = "\u00B3",
    "4" = "\u2074",
    "5" = "\u2075",
    "6" = "\u2076",
    "7" = "\u2077",
    "8" = "\u2078",
    "9" = "\u2079",
    "-" = "\u207B",
    "+" = "\u207A"
  )

  paste0(map[chars], collapse = "")
}

format_q <- function(q) {

  if (is.na(q)) {
    return("")
  }

  if (q == 0 || q < 1e-300) {
    return(
      paste0(
        "q < 1 \u00D7 10",
        superscript_number(-300)
      )
    )
  }

  exponent <- floor(log10(q))
  mantissa <- q / 10^exponent

  paste0(
    "q = ",
    sprintf("%.1f", mantissa),
    " \u00D7 10",
    superscript_number(exponent)
  )
}

df$q_label <- vapply(
  df$q,
  format_q,
  character(1)
)

df$a_label <- paste0(
  "a = ",
  format(
    df$a,
    big.mark = ",",
    scientific = FALSE
  )
)

# ------------------------------------------------------------
# Console output
# ------------------------------------------------------------
cat("\n")
cat("====================================================================\n")
cat("FIGURE 4 - PRIORITY SIGNAL-LABEL DISCORDANT PAIRS\n")
cat("====================================================================\n")

console_df <- df[
  ,
  c(
    "Domain",
    "Drug",
    "Clinical_concept",
    "a",
    "ROR",
    "ROR_lower95",
    "ROR_upper95",
    "IC025",
    "EB05",
    "q",
    "reporting_years"
  )
]

console_df$ROR <- round(console_df$ROR, 2)
console_df$ROR_lower95 <- round(console_df$ROR_lower95, 2)
console_df$ROR_upper95 <- round(console_df$ROR_upper95, 2)
console_df$IC025 <- round(console_df$IC025, 2)
console_df$EB05 <- round(console_df$EB05, 2)

print(
  console_df,
  row.names = FALSE
)

cat("\nSelection rule\n")
cat("--------------\n")
cat(
  "Robust + temporally repeated + Not identified + a >=20;\n"
)
cat(
  "up to two highest-EB05 display pairs per oral domain.\n"
)
cat(
  "Fluconazole-oral candidiasis was not prioritized for the main display\n"
)
cat(
  "because candidiasis appears in its labeling as an indication/dosing context.\n"
)
cat(
  "Cisplatin-oral candidiasis is displayed instead.\n"
)
cat("====================================================================\n\n")

# ------------------------------------------------------------
# Forest plot
# ------------------------------------------------------------
p <- ggplot(
  df,
  aes(
    x = ROR,
    y = pair_key
  )
) +

  # Null line
  geom_vline(
    xintercept = 1,
    linetype = "22",
    linewidth = 0.75,
    color = col_ref
  ) +

  # 95% CI
  geom_segment(
    aes(
      x = ROR_lower95,
      xend = ROR_upper95,
      y = pair_key,
      yend = pair_key
    ),
    linewidth = 1.25,
    color = col_ci,
    lineend = "round"
  ) +

  # CI end caps
  geom_errorbar(
    aes(
      xmin = ROR_lower95,
      xmax = ROR_upper95
    ),
    orientation = "y",
    width = 0.12,
    linewidth = 0.85,
    color = col_ci
  ) +

  # Main estimate
  geom_point(
    shape = 21,
    size = 5.0,
    stroke = 1.1,
    fill = col_point,
    color = "white"
  ) +

  # Co-report count
  geom_text(
    aes(
      x = 365,
      label = a_label
    ),
    family = "sans",
    fontface = "bold",
    size = 4.05,
    hjust = 0,
    color = col_text
  ) +

  # BH-FDR q
  geom_text(
    aes(
      x = 620,
      label = q_label
    ),
    family = "sans",
    size = 3.45,
    hjust = 0,
    color = col_muted
  ) +

  # Right-side column headers
  annotate(
    "text",
    x = 365,
    y = Inf,
    label = "Co-reports",
    family = "sans",
    fontface = "bold",
    size = 3.45,
    hjust = 0,
    vjust = 1.6,
    color = col_text
  ) +
  annotate(
    "text",
    x = 620,
    y = Inf,
    label = "BH-FDR q",
    family = "sans",
    fontface = "bold",
    size = 3.45,
    hjust = 0,
    vjust = 1.6,
    color = col_text
  ) +

  # Domain facets
  facet_grid(
    Domain ~ .,
    scales = "free_y",
    space = "free_y",
    switch = "y"
  ) +

  # Log scale
  scale_x_log10(
    limits = c(1, 1000),
    breaks = c(
      1, 2, 5, 10, 20, 50,
      100, 200, 500, 1000
    ),
    labels = c(
      "1", "2", "5", "10", "20", "50",
      "100", "200", "500", "1000"
    ),
    expand = c(0, 0)
  ) +

  # Hide domain prefix from pair key
  scale_y_discrete(
    labels = function(x) {
      sub("^.*___", "", x)
    }
  ) +

  labs(
    x = "Reporting odds ratio (95% CI), logarithmic scale",
    y = NULL
  ) +

  coord_cartesian(
    clip = "off"
  ) +

  theme_classic(
    base_family = "sans",
    base_size = 12
  ) +

  theme(
    # Pair labels
    axis.text.y = ggtext::element_markdown(
      size = 11.3,
      color = col_text,
      lineheight = 1.02,
      margin = margin(r = 10)
    ),

    # X axis
    axis.title.x = element_text(
      size = 13.5,
      face = "bold",
      margin = margin(t = 12)
    ),

    axis.text.x = element_text(
      size = 10.8,
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

    panel.grid.minor.x = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),

    # Domain strips
    strip.placement = "outside",

    strip.background = element_rect(
      fill = col_strip,
      color = NA
    ),

    strip.text.y.left = element_text(
      angle = 0,
      face = "bold",
      size = 10.2,
      color = col_text,
      hjust = 1,
      margin = margin(r = 8)
    ),

    panel.spacing.y = unit(
      2.3,
      "mm"
    ),

    # Enough right margin for a and q columns
    plot.margin = margin(
      t = 8,
      r = 105,
      b = 10,
      l = 6
    )
  )

# ------------------------------------------------------------
# Display in RStudio
# ------------------------------------------------------------
print(p)

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------
stem <- file.path(
  output_dir,
  "Figure4_priority_discordant_pairs_forest_v3_no_subtitle"
)

ggsave(
  paste0(stem, ".png"),
  p,
  width = 200,
  height = 175,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(stem, ".tiff"),
  p,
  width = 200,
  height = 175,
  units = "mm",
  dpi = 600,
  compression = "lzw",
  bg = "white"
)

if (requireNamespace("svglite", quietly = TRUE)) {
  ggsave(
    paste0(stem, ".svg"),
    p,
    width = 200,
    height = 175,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

ggsave(
  paste0(stem, ".pdf"),
  p,
  width = 200,
  height = 175,
  units = "mm",
  device = cairo_pdf,
  bg = "white"
)

write.csv(
  df,
  paste0(stem, "_data.csv"),
  row.names = FALSE
)

cat("\nSaved Figure 4 files\n")
cat("--------------------\n")
cat(paste0(stem, ".png\n"))
cat(paste0(stem, ".tiff\n"))
cat(paste0(stem, ".pdf\n"))

if (requireNamespace("svglite", quietly = TRUE)) {
  cat(paste0(stem, ".svg\n"))
}

cat(paste0(stem, "_data.csv\n"))

message(
  "\nFigure 4 displayed in RStudio and saved to: ",
  output_dir
)
