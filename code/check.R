# Validate the published files of SynthVisCom.
# Run from the repository root:  Rscript code/check.R
# Stops with an error at the first failed check; prints "All checks passed." otherwise.

if (!file.exists("code/generator.R")) stop("Run this script from the repository root.")
source("code/generator.R")

n_checks <- 0
check <- function(ok, what) {
  if (!isTRUE(all(ok))) stop("Check failed: ", what, call. = FALSE)
  n_checks <<- n_checks + 1
}
read <- function(path) utils::read.csv(path, stringsAsFactors = FALSE, na.strings = "")

designs <- read("data/synthetic_designs.csv")
participants <- read("data/synthetic_participants.csv")
responses <- read("data/synthetic_responses.csv")
codebook <- read("metadata/codebook.csv")

# 1. Files are intact and reproducible --------------------------------------
sums <- read.table("MD5SUMS", col.names = c("md5", "file"), stringsAsFactors = FALSE)
check(unname(tools::md5sum(sums$file)) == sums$md5, "files match MD5SUMS")
for (f in sums$file) check(!as.raw(13) %in% readBin(f, "raw", file.size(f)), paste(f, "has LF line endings"))

study <- vc_generate()
same <- function(back, ref) {
  for (col in names(ref)) storage.mode(back[[col]]) <- storage.mode(ref[[col]])
  isTRUE(all.equal(back, ref, check.attributes = FALSE))
}
check(same(designs, study$designs), "generator reproduces synthetic_designs.csv")
check(same(participants, study$participants), "generator reproduces synthetic_participants.csv")
check(same(responses, study$responses), "generator reproduces synthetic_responses.csv")
check(identical(vc_generate_designs(50, seed = 7), vc_generate_designs(50, seed = 7)), "same seed, same data")
check(!identical(vc_generate_designs(50, seed = 7), vc_generate_designs(50, seed = 8)), "seed changes data")
set.seed(42); expected <- runif(3)
set.seed(42); invisible(vc_generate(20, 10, 5, seed = 1))
check(identical(runif(3), expected), "generator restores the caller's random state")

# 2. Structure and keys -----------------------------------------------------
check(identical(dim(designs), c(2000L, 24L)), "designs has 2,000 rows and 24 columns")
check(identical(dim(participants), c(1000L, 7L)), "participants has 1,000 rows and 7 columns")
check(identical(dim(responses), c(20000L, 12L)), "responses has 20,000 rows and 12 columns")
check(!anyDuplicated(designs$design_id), "design_id is unique")
check(!anyDuplicated(participants$participant_id), "participant_id is unique")
check(!anyDuplicated(responses$response_id), "response_id is unique")
check(responses$design_id %in% designs$design_id, "responses link to designs")
check(responses$participant_id %in% participants$participant_id, "responses link to participants")
check(table(responses$participant_id) == 20, "each participant has 20 responses")
check(!anyDuplicated(responses[c("participant_id", "design_id")]), "no participant sees a design twice")

# 3. Values stay in their documented ranges ---------------------------------
check(designs$contrast_ratio >= 1.2 & designs$contrast_ratio <= 21, "contrast_ratio in 1.2-21")
check(designs$mean_saturation >= 0 & designs$mean_saturation <= 1, "mean_saturation in 0-1")
check(designs$visual_complexity >= 0 & designs$visual_complexity <= 100, "visual_complexity in 0-100")
check(is.na(designs$chart_type) == (designs$artefact_type != "data_chart"), "chart_type only for data charts")
check(is.na(designs$data_ink_ratio) == !designs$artefact_type %in% c("data_chart", "infographic"),
      "data_ink_ratio only for data charts and infographics")
check(sum(is.na(participants)) == 0 && sum(is.na(responses)) == 0, "no missing values outside designs")
check(responses$comprehension_score %in% 0:5, "comprehension_score in 0-5")
check(responses$aesthetic_rating %in% 1:7 & responses$preference_rating %in% 1:7, "ratings in 1-7")
check(responses$cognitive_load >= 0 & responses$cognitive_load <= 100, "cognitive_load in 0-100")
check(responses$trial %in% 1:20, "trial in 1-20")

# 4. The codebook documents every column with the right type ----------------
tables <- list(designs = study$designs, participants = study$participants, responses = study$responses)
for (name in names(tables)) {
  rows <- codebook[codebook$table == name, ]
  check(identical(rows$variable, names(tables[[name]])), paste("codebook lists every column of", name))
  types <- vapply(tables[[name]], function(x) class(x)[1], "")
  check(identical(unname(types), rows$type), paste("codebook types match", name))
}
check(codebook$role %in% c("identifier", "attribute", "derived", "outcome"), "codebook roles are valid")

# 5. Images match their designs ----------------------------------------------
images <- read("metadata/images.csv")
check(identical(codebook$variable[codebook$table == "images"], names(images)), "codebook lists every column of images")
check(identical(images$design_id, designs$design_id), "one image per design, in design order")
check(file.exists(images$image_file), "every image file exists")
check(length(list.files("images", pattern = "\\.png$")) == nrow(designs), "no extra files in images/")
check(unname(tools::md5sum(images$image_file)) == images$md5, "images match their MD5 in images.csv")
png_size <- function(path) {
  b <- readBin(path, "raw", 24)
  int <- function(x) sum(as.integer(x) * 256^(3:0))
  c(int(b[17:20]), int(b[21:24]))
}
sizes <- t(vapply(images$image_file, png_size, numeric(2)))
check(sizes[, 1] == images$width_px & sizes[, 2] == images$height_px, "PNG dimensions match images.csv")
expected <- t(vapply(designs$artefact_type, function(type) {
  switch(type, poster = c(566, 800), infographic = c(450, 800), data_chart = c(800, 600),
         social_media_image = c(800, 800), slide = c(800, 450))
}, numeric(2)))
check(sizes[, 1] == expected[, 1] & sizes[, 2] == expected[, 2], "image proportions follow artefact_type")
check(abs(images$rendered_contrast / designs$contrast_ratio - 1) < 0.03, "drawn contrast matches contrast_ratio")
check(images$words_drawn <= designs$word_count, "no more words drawn than word_count")
check(lengths(strsplit(images$palette, " ")) == designs$n_colours, "palette has n_colours colours")

# 6. Known effects can be recovered ------------------------------------------
eff <- vc_true_effects()
check(!anyDuplicated(paste(eff$outcome, eff$term)) && all(is.finite(eff$value)), "true effects are complete")
all_data <- merge(merge(responses, designs), participants)
below <- pmin(log(all_data$contrast_ratio / 4.5), 0)
fit <- stats::glm(cbind(comprehension_score, 5 - comprehension_score) ~ below + focal_point,
                  family = stats::binomial, data = all_data)
check(coef(fit)[["below"]] > 0.8, "low contrast lowers comprehension")
fit <- stats::glm(recall_24h ~ human_face, family = stats::binomial, data = all_data)
check(coef(fit)[["human_faceTRUE"]] > 0.3, "faces raise recall")
fit <- stats::lm(aesthetic_rating ~ alignment_consistency * design_expertise, data = all_data)
check(coef(fit)[["alignment_consistency:design_expertiseprofessional"]] > 0.5,
      "alignment matters more to professionals")
modified <- eff
modified$value[modified$outcome == "recall_24h" & modified$term == "intercept"] <- 3
check(mean(vc_generate(50, 50, 10, seed = 1, effects = modified)$responses$recall_24h) > 0.9,
      "changing an effect changes the simulated responses")

message("All checks passed (", n_checks, " checks).")
