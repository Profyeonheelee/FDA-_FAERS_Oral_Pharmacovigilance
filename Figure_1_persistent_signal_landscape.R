# Figure 1. Persistent oral pharmacovigilance signals and current-label status

library(ggplot2)
library(grid)

project_root <- Sys.getenv("FAERS_PROJECT_ROOT", unset = getwd())
input_file <- file.path(project_root, "data", "06_publication_outputs", "figure1_review_unit_landscape_data.csv")
output_dir <- file.path(project_root, "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

df <- read.csv(input_file, stringsAsFactors = FALSE, check.names = FALSE)
required_columns <- c(
  "canonical_pharmacovigilance_ingredient", "Domain", "Clinical_concept",
  "final_label_status", "max_EB05", "max_a"
)
missing_columns <- setdiff(required_columns, names(df))
if (length(missing_columns) > 0) {
  stop(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
}
stopifnot(nrow(df) == 726)
stopifnot(sum(df$final_label_status == "Explicitly represented") == 363)
stopifnot(sum(df$final_label_status == "Broadly represented") == 41)
stopifnot(sum(df$final_label_status == "Not identified") == 322)

domain_order <- c(
  "Salivary dysfunction", "Oral mucosal / tongue", "Taste / chemosensory",
  "Jaw / alveolar bone", "Oral infection", "Dental / pulpal",
  "Gingival / periodontal"
)
concept_order <- c(
  "Xerostomia", "Hypersalivation", "Aptyalism", "Stomatitis",
  "Oral ulceration", "Glossitis", "Glossodynia", "Tongue ulceration",
  "Taste disturbance", "Ageusia", "Hypogeusia", "Osteonecrosis of jaw",
  "Oral candidiasis", "Tooth discolouration", "Dental caries",
  "Tooth infection", "Root canal infection", "Gingival enlargement",
  "Gingival bleeding", "Gingivitis", "Periodontitis"
)
status_order <- c("Explicitly represented", "Broadly represented", "Not identified")

df$Domain <- factor(df$Domain, levels = domain_order)
df$Clinical_concept <- factor(df$Clinical_concept, levels = rev(concept_order))
df$final_label_status <- factor(df$final_label_status, levels = status_order)
df$max_EB05 <- as.numeric(df$max_EB05)
df$max_a <- as.numeric(df$max_a)

concept_n <- aggregate(
  canonical_pharmacovigilance_ingredient ~ Domain + Clinical_concept,
  data = df,
  FUN = length
)
names(concept_n)[3] <- "n"
concept_n$count_label <- paste0("n=", concept_n$n)

domain_n <- aggregate(canonical_pharmacovigilance_ingredient ~ Domain, data = df, FUN = length)
names(domain_n)[2] <- "n"
domain_labels <- setNames(
  paste0(as.character(domain_n$Domain), "  (n=", domain_n$n, ")"),
  as.character(domain_n$Domain)
)

status_colors <- c(
  "Explicitly represented" = "#00A087",
  "Broadly represented" = adjustcolor("#4DBBD5", alpha.f = 0.65),
  "Not identified" = "#A23B2A"
)

set.seed(20260910)
p <- ggplot(df, aes(x = max_EB05, y = Clinical_concept)) +
  geom_vline(xintercept = 2, linetype = "22", linewidth = 0.7, color = "#666666") +
  geom_point(
    aes(fill = final_label_status, size = max_a),
    shape = 21, color = "#666666", stroke = 0.25, alpha = 0.82,
    position = position_jitter(width = 0, height = 0.16, seed = 20260910)
  ) +
  geom_text(
    data = concept_n,
    aes(x = Inf, y = Clinical_concept, label = count_label),
    inherit.aes = FALSE, hjust = -0.08, size = 3.0,
    fontface = "bold", color = "#222222"
  ) +
  facet_grid(
    Domain ~ ., scales = "free_y", space = "free_y", switch = "y",
    labeller = labeller(Domain = domain_labels), drop = FALSE
  ) +
  scale_fill_manual(values = status_colors, name = NULL, drop = FALSE) +
  scale_size_continuous(
    trans = "sqrt", range = c(1.5, 6.0), breaks = c(10, 30, 100, 300, 1000),
    name = expression("Co-reports, " * italic(a))
  ) +
  scale_x_log10(
    breaks = c(2, 3, 5, 10, 20, 50, 100, 200),
    labels = c("2", "3", "5", "10", "20", "50", "100", "200"),
    expand = expansion(mult = c(0.02, 0.13))
  ) +
  coord_cartesian(clip = "off") +
  labs(
    x = "Maximum EB05 within drug–clinical concept review unit, logarithmic scale",
    y = NULL
  ) +
  theme_classic(base_family = "sans", base_size = 12) +
  theme(
    axis.text.y = element_text(size = 9.8, color = "#222222", margin = margin(r = 7)),
    axis.text.x = element_text(size = 10.4, color = "#222222"),
    axis.title.x = element_text(size = 12.4, face = "bold", margin = margin(t = 10)),
    axis.line.y = element_blank(), axis.ticks.y = element_blank(),
    panel.grid.major.x = element_line(color = "#E8E8E8", linewidth = 0.4),
    panel.grid.minor = element_blank(), strip.placement = "outside",
    strip.background = element_rect(fill = "#F4F4F4", color = NA),
    strip.text.y.left = element_text(angle = 0, face = "bold", size = 9.6, hjust = 1, margin = margin(r = 8)),
    panel.spacing.y = unit(2.0, "mm"), legend.position = "top",
    legend.justification = "center", legend.box = "vertical",
    legend.title = element_text(face = "bold", size = 10.2),
    legend.text = element_text(size = 10.0), plot.margin = margin(5, 34, 8, 5)
  )

print(p)
stem <- file.path(output_dir, "Figure1_persistent_signal_landscape")
ggsave(paste0(stem, ".png"), p, width = 195, height = 190, units = "mm", dpi = 600, bg = "white")
ggsave(paste0(stem, ".tiff"), p, width = 195, height = 190, units = "mm", dpi = 600, compression = "lzw", bg = "white")
ggsave(paste0(stem, ".pdf"), p, width = 195, height = 190, units = "mm", device = cairo_pdf, bg = "white")
if (requireNamespace("svglite", quietly = TRUE)) {
  ggsave(paste0(stem, ".svg"), p, width = 195, height = 190, units = "mm", device = svglite::svglite, bg = "white")
}
