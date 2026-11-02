# Getting started with SynthVisCom
# Run from the repository root:  Rscript examples/getting-started.R
# ALL DATA ARE SYNTHETIC: results describe the simulation model, not real audiences.

# Load the three linked tables --------------------------------------------
designs <- read.csv("data/synthetic_designs.csv", na.strings = "")
participants <- read.csv("data/synthetic_participants.csv")
responses <- read.csv("data/synthetic_responses.csv")
codebook <- read.csv("metadata/codebook.csv")
true_effects <- read.csv("metadata/true_effects.csv")

sapply(list(designs = designs, participants = participants, responses = responses), dim)
head(codebook[, c("table", "variable", "unit", "description")])

# Join them: one row per response, with design and participant attributes --
study <- merge(merge(responses, designs, by = "design_id"),
               participants, by = "participant_id")
dim(study)

# A first look: comprehension by WCAG contrast band -----------------------
study$contrast_band <- cut(study$contrast_ratio, c(0, 3, 4.5, 7, 21),
                           labels = c("< 3", "3-4.5", "4.5-7", "> 7"))
means <- tapply(study$comprehension_score, study$contrast_band, mean)
print(round(means, 2))
barplot(means, ylim = c(0, 5), col = "#0072B2", border = NA,
        xlab = "Text contrast ratio", ylab = "Mean correct answers (of 5)")

# Generate a fresh synthetic study, e.g. one per student or exam ----------
source("code/generator.R")
small <- vc_generate(n_designs = 200, n_participants = 60,
                     trials_per_participant = 10, seed = 101)
sapply(small, nrow)

# A "what if" scenario: faces have no effect on recall --------------------
eff <- vc_true_effects()
eff$value[eff$outcome == "recall_24h" & eff$term == "human_face"] <- 0
no_faces <- vc_generate(seed = 2026, effects = eff)
