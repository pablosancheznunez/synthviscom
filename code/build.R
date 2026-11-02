# Rebuild every published file of SynthVisCom from scratch.
# Run from the repository root:  Rscript code/build.R
# Needs only base R (with cairo PNG support, standard on Windows, macOS and Linux builds).
# Everything is generated from fixed seeds (data 2026, images 3000), so running this again gives
# byte-identical files (checked by code/check.R against MD5SUMS and metadata/images.csv).

if (!file.exists("code/generator.R")) stop("Run this script from the repository root.")
source("code/generator.R")

study <- vc_generate(n_designs = 2000, n_participants = 1000,
                     trials_per_participant = 20, seed = 2026)

# CSV in UTF-8 with LF line endings (binary mode), so the files are identical on every OS.
write_csv_lf <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con))
  utils::write.csv(x, con, row.names = FALSE, na = "")
}

dir.create("data", showWarnings = FALSE)
dir.create("metadata", showWarnings = FALSE)
files <- c(
  "data/synthetic_designs.csv", "data/synthetic_participants.csv", "data/synthetic_responses.csv",
  "metadata/codebook.csv", "metadata/true_effects.csv"
)
tables <- list(study$designs, study$participants, study$responses, vc_codebook(), vc_true_effects())
for (i in seq_along(files)) write_csv_lf(tables[[i]], files[i])

# Read the data back and check that the CSV files hold exactly what was generated.
for (name in c("designs", "participants", "responses")) {
  back <- utils::read.csv(paste0("data/synthetic_", name, ".csv"),
                          stringsAsFactors = FALSE, na.strings = "")
  ref <- study[[name]]
  for (col in names(ref)) storage.mode(back[[col]]) <- storage.mode(ref[[col]])
  stopifnot(isTRUE(all.equal(back, ref, check.attributes = FALSE)))
}

# One PNG per design, drawn from its variables, plus a manifest with what was actually drawn.
# PNGs are byte-identical on the same system; fonts can differ slightly between operating systems.
source("code/render.R")
message("Rendering ", nrow(study$designs), " images (a few minutes)...")
images <- vc_render_images(study$designs, dir = "images", seed = 3000)
images$md5 <- unname(tools::md5sum(images$image_file))
write_csv_lf(images, "metadata/images.csv")
files <- c(files, "metadata/images.csv")

sums <- tools::md5sum(files)
con <- file("MD5SUMS", open = "wb")
writeLines(paste0(unname(sums), "  ", files), con)
close(con)
message("Built ", length(files), " files and MD5SUMS.")
