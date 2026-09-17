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
# Nature/NPG-inspired palette
# ------------------------------------------------------------
col_blue   <- "#3C5488"
col_cyan   <- "#4DBBD5"
col_teal   <- "#00A087"
col_red    <- "#E64B35"
col_slate  <- "#8491B4"
col_text   <- "#222222"
col_muted  <- "#666666"
col_rule   <- "#D9D9D9"

fill_blue  <- "#F1F3F8"
fill_teal  <- "#F0F8F6"
fill_cyan  <- "#F1F8FA"
fill_red   <- "#FDF2EF"
fill_sens  <- "#F7F7FA"

# ------------------------------------------------------------
# Locked study results
# ------------------------------------------------------------
results <- data.frame(
  metric = c(
    "FAERS study period",
    "Quarterly extracts",
    "Deduplicated, non-deleted reports",
    "Canonical pharmacovigilance ingredients",
    "Ingredients with >=1 true-PS report",
    "Primary drug universe (true PS >=500)",
    "Sensitivity drug universe (true PS >=100)",
    "Locked oral PTs",
    "Primary inferential oral PTs",
    "Primary drug-PT pairs tested",
    "Pairs with >=10 co-reports",
    "Robust primary signals",
    "Robust + temporally repeated PT-level signals",
    "Unique drugs with persistent robust signals",
    "Drug-clinical concept label-review units",
    "Explicitly represented",
    "Broadly represented",
    "Any representation",
    "Not identified",
    "Unresolved"
  ),
  value = c(
    "2004 Q1-2026 Q2",
    "90",
    "20,616,119",
    "1,647",
    "1,615",
    "1,119",
    "1,390",
    "72",
    "25",
    "27,975",
    "3,803",
    "791",
    "750",
    "368",
    "726",
    "363 (50.0%)",
    "41 (5.6%)",
    "404 (55.6%)",
    "322 (44.4%)",
    "0"
  ),
  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# Console output
# ------------------------------------------------------------
cat("\n")
cat("====================================================================\n")
cat("FIGURE 0 - STUDY DESIGN AND ANALYTIC SELECTION\n")
cat("====================================================================\n")
print(results, row.names = FALSE)

cat("\nMain analytic flow\n")
cat("------------------\n")
cat("A. Data foundation\n")
cat("   90 FAERS quarters -> 20,616,119 reports -> 1,647 ingredients\n")
cat("   -> 1,119 primary drugs (true PS >=500)\n")
cat("   72 locked oral PTs -> 25 primary inferential PTs\n\n")

cat("B. Primary signal detection\n")
cat("   1,119 drugs x 25 PTs = 27,975 pairs\n")
cat("   -> 3,803 pairs with >=10 co-reports\n")
cat("   -> 791 robust signals\n")
cat("   -> 750 robust + temporally repeated signals\n\n")

cat("C. FDA label concordance\n")
cat("   750 persistent PT-level signals\n")
cat("   -> 726 drug-clinical concept review units\n")
cat("   -> 404 represented (55.6%)\n")
cat("      -> 363 explicit (50.0%)\n")
cat("      -> 41 broad (5.6%)\n")
cat("   -> 322 not identified (44.4%)\n")
cat("   -> 0 unresolved\n\n")

cat("Sensitivity analysis\n")
cat("   1,390 drugs with true PS >=100; all 791 primary robust signals recovered.\n")
cat("====================================================================\n\n")

# ------------------------------------------------------------
# Layout
# ------------------------------------------------------------
nodes <- data.frame(
  id = c(
    "quarters", "reports", "ingredients", "ps1",
    "oral72", "oral25",
    "pairs", "eligible", "robust", "persistent",
    "concepts", "represented", "notidentified", "explicit", "broad"
  ),

  x = c(
    1.25, 3.15, 5.05, 6.85,
    3.15, 6.35,
    9.20, 11.05, 12.90, 14.60,
    17.35, 19.55, 19.55, 21.80, 21.80
  ),

  y = c(
    5.25, 5.25, 5.25, 5.25,
    2.20, 2.20,
    3.78, 3.78, 3.78, 3.78,
    3.78, 5.05, 2.45, 5.65, 4.45
  ),

  w = c(
    1.60, 1.68, 1.75, 1.78,
    1.72, 1.82,
    1.72, 1.72, 1.66, 1.82,
    1.92, 1.90, 1.90, 1.72, 1.72
  ),

  h = c(
    1.22, 1.22, 1.22, 1.22,
    1.22, 1.22,
    1.22, 1.22, 1.22, 1.22,
    1.28, 1.28, 1.28, 1.02, 1.02
  ),

  value = c(
    "90",
    "20,616,119",
    "1,647",
    "1,119",
    "72",
    "25",
    "27,975",
    "3,803",
    "791",
    "750",
    "726",
    "404\n(55.6%)",
    "322\n(44.4%)",
    "363\n(50.0%)",
    "41\n(5.6%)"
  ),

  label = c(
    "Quarterly FAERS\nextracts\n2004 Q1-2026 Q2",
    "Deduplicated,\nnon-deleted\nreports",
    "Canonical\npharmacovigilance\ningredients",
    "Primary drug\nuniverse\ntrue PS >=500",
    "Locked oral\nMedDRA\nPTs",
    "Primary inferential\noral\nPTs",
    "Drug-PT\npairs\ntested",
    "Pairs with >=10\nco-reports",
    "Robust\nsignals",
    "Robust + temporally\nrepeated\nsignals",
    "Drug-clinical concept\nlabel-review\nunits",
    "Any label\nrepresentation",
    "Not identified",
    "Explicit",
    "Broad"
  ),

  type = c(
    "drug", "drug", "drug", "drug",
    "ontology", "ontology",
    "signal", "signal", "signal", "signal",
    "label", "represented", "discordant", "represented", "represented"
  ),
  stringsAsFactors = FALSE
)

fill_map <- c(
  drug = fill_blue,
  ontology = fill_teal,
  signal = fill_teal,
  label = fill_cyan,
  represented = fill_teal,
  discordant = fill_red
)

border_map <- c(
  drug = col_blue,
  ontology = col_teal,
  signal = col_teal,
  label = col_cyan,
  represented = col_teal,
  discordant = col_red
)

nodes$fill <- fill_map[nodes$type]
nodes$border <- border_map[nodes$type]

node <- function(id) nodes[nodes$id == id, , drop = FALSE]

# ------------------------------------------------------------
# Rounded box helper
# ------------------------------------------------------------
add_round_box <- function(p, x, y, w, h, fill, border,
                          radius_mm = 2.8, lwd = 1.65,
                          shadow = TRUE) {

  if (shadow) {
    shadow_grob <- roundrectGrob(
      x = 0.5, y = 0.5,
      width = 0.98, height = 0.98,
      r = unit(radius_mm, "mm"),
      gp = gpar(
        fill = adjustcolor("#000000", alpha.f = 0.045),
        col = NA
      )
    )

    p <- p + annotation_custom(
      shadow_grob,
      xmin = x - w/2 + 0.040,
      xmax = x + w/2 + 0.040,
      ymin = y - h/2 - 0.040,
      ymax = y + h/2 - 0.040
    )
  }

  box_grob <- roundrectGrob(
    x = 0.5, y = 0.5,
    width = 0.98, height = 0.98,
    r = unit(radius_mm, "mm"),
    gp = gpar(
      fill = fill,
      col = border,
      lwd = lwd
    )
  )

  p + annotation_custom(
    box_grob,
    xmin = x - w/2,
    xmax = x + w/2,
    ymin = y - h/2,
    ymax = y + h/2
  )
}

# ------------------------------------------------------------
# Arrow helpers
# ------------------------------------------------------------
straight_edge <- function(from, to, gap = 0.06) {
  a <- node(from)
  b <- node(to)

  data.frame(
    x = a$x + a$w/2 + gap,
    y = a$y,
    xend = b$x - b$w/2 - gap,
    yend = b$y
  )
}

# Keep straight arrows only where no overlap is possible
edges_straight <- rbind(
  straight_edge("quarters", "reports"),
  straight_edge("reports", "ingredients"),
  straight_edge("ingredients", "ps1"),
  straight_edge("oral72", "oral25"),
  straight_edge("pairs", "eligible"),
  straight_edge("eligible", "robust"),
  straight_edge("robust", "persistent"),
  straight_edge("persistent", "concepts")
)

# ------------------------------------------------------------
# a -> b convergence:
# route drug and oral streams into two separate entry points
# so arrowheads do not overlap.
# ------------------------------------------------------------
ps1 <- node("ps1")
oral25 <- node("oral25")
pairs <- node("pairs")

edges_converge <- data.frame(
  x = c(
    ps1$x + ps1$w/2 + 0.03,
    oral25$x + oral25$w/2 + 0.03
  ),
  y = c(
    ps1$y,
    oral25$y
  ),
  xend = c(
    pairs$x - pairs$w/2 - 0.06,
    pairs$x - pairs$w/2 - 0.06
  ),
  yend = c(
    pairs$y + 0.34,
    pairs$y - 0.34
  ),
  curvature = c(0.18, -0.18)
)

# ------------------------------------------------------------
# c branching:
# use distinct upper/lower exits and entries
# ------------------------------------------------------------
concepts <- node("concepts")
represented <- node("represented")
notidentified <- node("notidentified")
explicit <- node("explicit")
broad <- node("broad")

edges_label_main <- data.frame(
  x = c(
    concepts$x + concepts$w/2 + 0.03,
    concepts$x + concepts$w/2 + 0.03
  ),
  y = c(
    concepts$y + 0.28,
    concepts$y - 0.28
  ),
  xend = c(
    represented$x - represented$w/2 - 0.05,
    notidentified$x - notidentified$w/2 - 0.05
  ),
  yend = c(
    represented$y,
    notidentified$y
  ),
  curvature = c(-0.16, 0.16)
)

edges_label_sub <- data.frame(
  x = c(
    represented$x + represented$w/2 + 0.03,
    represented$x + represented$w/2 + 0.03
  ),
  y = c(
    represented$y + 0.25,
    represented$y - 0.25
  ),
  xend = c(
    explicit$x - explicit$w/2 - 0.05,
    broad$x - broad$w/2 - 0.05
  ),
  yend = c(
    explicit$y,
    broad$y
  ),
  curvature = c(-0.16, 0.16)
)

# ------------------------------------------------------------
# Base plot
# ------------------------------------------------------------
p <- ggplot() +

  # Subtle separators
  annotate(
    "segment",
    x = 7.85, xend = 7.85,
    y = 0.55, yend = 6.95,
    color = col_rule, linewidth = 0.50
  ) +
  annotate(
    "segment",
    x = 15.65, xend = 15.65,
    y = 0.55, yend = 6.95,
    color = col_rule, linewidth = 0.50
  ) +

  # Panel letters
  annotate(
    "text", x = 0.50, y = 6.83, label = "a",
    family = "sans", fontface = "bold",
    size = 5.5, hjust = 0
  ) +
  annotate(
    "text", x = 8.20, y = 6.83, label = "b",
    family = "sans", fontface = "bold",
    size = 5.5, hjust = 0
  ) +
  annotate(
    "text", x = 15.95, y = 6.83, label = "c",
    family = "sans", fontface = "bold",
    size = 5.5, hjust = 0
  ) +

  # Panel subtitles
  annotate(
    "text", x = 4.15, y = 6.82,
    label = "Data foundation",
    family = "sans", fontface = "bold",
    size = 5.6
  ) +
  annotate(
    "text", x = 11.85, y = 6.82,
    label = "Primary signal detection",
    family = "sans", fontface = "bold",
    size = 5.6
  ) +
  annotate(
    "text", x = 19.55, y = 6.82,
    label = "FDA label concordance",
    family = "sans", fontface = "bold",
    size = 5.6
  ) +

  # Stream labels
  annotate(
    "text", x = 0.80, y = 6.03,
    label = "Drug-report stream",
    family = "sans", fontface = "bold",
    size = 3.7, color = col_blue,
    hjust = 0
  ) +
  annotate(
    "text", x = 0.80, y = 2.95,
    label = "Oral-event stream",
    family = "sans", fontface = "bold",
    size = 3.7, color = col_teal,
    hjust = 0
  ) +

  # Straight arrows: thicker and cleaner
  geom_segment(
    data = edges_straight,
    aes(x = x, y = y, xend = xend, yend = yend),
    color = col_slate,
    linewidth = 1.05,
    lineend = "round",
    arrow = arrow(
      length = unit(3.0, "mm"),
      angle = 24,
      type = "closed"
    )
  ) +

  # Curved convergence arrows
  geom_curve(
    data = edges_converge,
    aes(
      x = x, y = y,
      xend = xend, yend = yend,
      curvature = curvature
    ),
    color = col_slate,
    linewidth = 1.10,
    lineend = "round",
    arrow = arrow(
      length = unit(3.2, "mm"),
      angle = 24,
      type = "closed"
    )
  ) +

  # Curved label branches
  geom_curve(
    data = edges_label_main,
    aes(
      x = x, y = y,
      xend = xend, yend = yend,
      curvature = curvature
    ),
    color = col_slate,
    linewidth = 1.05,
    lineend = "round",
    arrow = arrow(
      length = unit(3.2, "mm"),
      angle = 24,
      type = "closed"
    )
  ) +

  geom_curve(
    data = edges_label_sub,
    aes(
      x = x, y = y,
      xend = xend, yend = yend,
      curvature = curvature
    ),
    color = col_slate,
    linewidth = 1.00,
    lineend = "round",
    arrow = arrow(
      length = unit(3.0, "mm"),
      angle = 24,
      type = "closed"
    )
  ) +

  # ----------------------------------------------------------
  # Dedicated explanation labels, moved ABOVE arrows / boxes
  # ----------------------------------------------------------
  annotate(
    "label",
    x = 8.15, y = 4.78,
    label = "Drug × PT\ncross-product",
    family = "sans",
    fontface = "bold",
    size = 3.15,
    label.size = 0,
    fill = "white",
    color = col_muted,
    lineheight = 0.95
  ) +

  annotate(
    "label",
    x = 15.55, y = 4.78,
    label = "Related PTs collapsed\ninto clinical concepts",
    family = "sans",
    fontface = "bold",
    size = 3.05,
    label.size = 0,
    fill = "white",
    color = col_muted,
    lineheight = 0.95
  ) +

  # Additional clear b-panel explanation, fully visible
  annotate(
    "text",
    x = 11.85, y = 5.35,
    label = "Prespecified filtering sequence",
    family = "sans",
    fontface = "bold",
    size = 3.15,
    color = col_teal
  ) +

  annotate(
    "text",
    x = 11.85, y = 5.02,
    label = "count threshold  ->  robust signal criteria  ->  temporal repetition",
    family = "sans",
    size = 2.75,
    color = col_muted
  ) +

  # Minor annotation
  annotate(
    "text",
    x = 5.05, y = 4.38,
    label = "1,615 ingredients had >=1 true-PS report",
    family = "sans",
    size = 2.65,
    color = col_muted
  ) +

  # Sensitivity callout
  annotate(
    "rect",
    xmin = 8.65, xmax = 15.10,
    ymin = 0.64, ymax = 1.56,
    fill = fill_sens,
    color = NA
  ) +
  annotate(
    "segment",
    x = 8.65, xend = 15.10,
    y = 1.56, yend = 1.56,
    color = col_slate,
    linewidth = 1.05
  ) +
  annotate(
    "text",
    x = 11.88, y = 1.25,
    label = "Sensitivity analysis: true PS >=100",
    family = "sans",
    fontface = "bold",
    size = 3.15,
    color = col_slate
  ) +
  annotate(
    "text",
    x = 11.88, y = 0.88,
    label = "1,390 drugs; all 791 primary robust signals recovered",
    family = "sans",
    size = 2.85,
    color = col_text
  ) +

  # c-panel note
  annotate(
    "text",
    x = 19.55, y = 1.28,
    label = "No label-review unit remained unresolved",
    family = "sans",
    size = 2.65,
    color = col_muted
  ) +

  coord_cartesian(
    xlim = c(0.05, 22.70),
    ylim = c(0.48, 6.95),
    clip = "off",
    expand = FALSE
  ) +

  theme_void(base_family = "sans") +

  theme(
    plot.margin = margin(0, 0, 0, 0)
  )

# ------------------------------------------------------------
# Add rounded boxes
# ------------------------------------------------------------
for (i in seq_len(nrow(nodes))) {
  p <- add_round_box(
    p,
    x = nodes$x[i],
    y = nodes$y[i],
    w = nodes$w[i],
    h = nodes$h[i],
    fill = nodes$fill[i],
    border = nodes$border[i],
    radius_mm = 2.8,
    lwd = 1.65,
    shadow = TRUE
  )
}

# ------------------------------------------------------------
# Add box text above the box layer
# ------------------------------------------------------------
p <- p +

  geom_text(
    data = nodes,
    aes(
      x = x,
      y = y + h*0.18,
      label = value,
      color = border
    ),
    family = "sans",
    fontface = "bold",
    size = 4.45,
    lineheight = 0.92,
    show.legend = FALSE
  ) +

  scale_color_identity() +

  geom_text(
    data = nodes,
    aes(
      x = x,
      y = y - h*0.18,
      label = label
    ),
    family = "sans",
    size = 3.0,
    lineheight = 0.92,
    color = col_text
  )

# ------------------------------------------------------------
# Show figure
# ------------------------------------------------------------
print(p)

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------
stem <- file.path(
  output_dir,
  "Figure0_study_analysis_flow_refined_v6_clean_arrows"
)

ggsave(
  paste0(stem, ".png"),
  p,
  width = 205,
  height = 78,
  units = "mm",
  dpi = 600,
  bg = "white"
)

ggsave(
  paste0(stem, ".tiff"),
  p,
  width = 205,
  height = 78,
  units = "mm",
  dpi = 600,
  compression = "lzw",
  bg = "white"
)

if (requireNamespace("svglite", quietly = TRUE)) {
  ggsave(
    paste0(stem, ".svg"),
    p,
    width = 205,
    height = 78,
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
}

ggsave(
  paste0(stem, ".pdf"),
  p,
  width = 205,
  height = 78,
  units = "mm",
  device = cairo_pdf,
  bg = "white"
)

write.csv(
  results,
  paste0(stem, "_results.csv"),
  row.names = FALSE
)

write.csv(
  nodes,
  paste0(stem, "_node_data.csv"),
  row.names = FALSE
)

cat("\nSaved Figure 0 files\n")
cat("--------------------\n")
cat(paste0(stem, ".png\n"))
cat(paste0(stem, ".tiff\n"))
cat(paste0(stem, ".pdf\n"))
if (requireNamespace("svglite", quietly = TRUE)) {
  cat(paste0(stem, ".svg\n"))
}
cat(paste0(stem, "_results.csv\n"))
cat(paste0(stem, "_node_data.csv\n"))

message(
  "\nFigure 0 displayed in RStudio and saved to: ",
  output_dir
)
