# SynthVisCom generator: simulates synthetic visual designs, participants and responses.
# Plain R (base, stats and utils only). Source this file, then call vc_generate().
# ALL DATA PRODUCED HERE ARE SYNTHETIC: they do not represent real people, designs or findings.
# Code licence: MIT (see LICENSE). Run code/build.R to rebuild the published files.

# Generating effects ------------------------------------------------------
# vc_true_effects() returns the true effects used to simulate the responses. Each row is one term of
# one outcome model; `scale` is logit, log, latent (a standard-normal latent variable cut into a 1-7
# rating), points (0-100 scale) or multiplier (applied to contrast). Terms ending in _sd are SDs.

vc_true_effects <- function() {
  e <- function(outcome, term, value, scale, description) {
    data.frame(outcome = outcome, term = term, value = value, scale = scale,
               description = description, stringsAsFactors = FALSE)
  }
  rbind(
    e("effective_contrast", "cvd_multiplier", 0.55, "multiplier",
      "Contrast above 1 is multiplied by this for red-green colour vision deficiency with complementary or triadic palettes, and for tritan deficiency with triadic palettes"),
    e("effective_contrast", "low_vision_multiplier", 0.60, "multiplier",
      "Contrast above 1 is multiplied by this for participants with low vision"),

    e("comprehension", "intercept", 0.60, "logit", "Log-odds of answering one of five questions correctly for a reference design and participant"),
    e("comprehension", "log_contrast_below_aa", 1.40, "logit", "Per unit of log(effective contrast / 4.5) when effective contrast is below 4.5:1"),
    e("comprehension", "log_contrast_above_aa", 0.15, "logit", "Per unit of log(effective contrast / 4.5) when effective contrast is at or above 4.5:1"),
    e("comprehension", "hierarchy_quadratic", -0.12, "logit", "Per squared distance of hierarchy_levels from 3"),
    e("comprehension", "log_word_count", -0.35, "logit", "Per unit of log(word_count / 50)"),
    e("comprehension", "visual_complexity", -0.015, "logit", "Per point of visual_complexity above 50"),
    e("comprehension", "focal_point", 0.30, "logit", "Design has a clear focal point"),
    e("comprehension", "visual_literacy", 0.02, "logit", "Per point of participant visual_literacy above 50"),
    e("comprehension", "data_ink_ratio", 1.20, "logit", "Per unit of data_ink_ratio above 0.6 (infographics and data charts)"),
    e("comprehension", "pie_chart", -0.35, "logit", "Data chart of type pie"),
    e("comprehension", "small_text_mobile", -0.12, "logit", "Per point of body text below 12 pt when viewed on a mobile phone"),
    e("comprehension", "design_sd", 0.35, "logit", "SD of the design random intercept"),
    e("comprehension", "participant_sd", 0.40, "logit", "SD of the participant random intercept"),

    e("time_to_first_fixation", "intercept", 6.10, "log", "Log milliseconds for a reference design"),
    e("time_to_first_fixation", "log_contrast", -0.10, "log", "Per unit of log(effective contrast / 4.5)"),
    e("time_to_first_fixation", "human_face", -0.20, "log", "Design shows a human face"),
    e("time_to_first_fixation", "focal_point", -0.15, "log", "Design has a clear focal point"),
    e("time_to_first_fixation", "saturation", -0.25, "log", "Per unit of mean_saturation above 0.5"),
    e("time_to_first_fixation", "visual_complexity", 0.006, "log", "Per point of visual_complexity above 50"),
    e("time_to_first_fixation", "residual_sd", 0.35, "log", "Residual SD"),

    e("dwell_time", "intercept", 1.50, "log", "Log seconds for a reference design viewed on a desktop"),
    e("dwell_time", "log_word_count", 0.35, "log", "Per unit of log(word_count / 50)"),
    e("dwell_time", "visual_complexity", 0.008, "log", "Per point of visual_complexity above 50"),
    e("dwell_time", "mobile", -0.25, "log", "Viewed on a mobile phone"),
    e("dwell_time", "aesthetic_latent", 0.10, "log", "Per SD of the design's latent aesthetic appeal"),
    e("dwell_time", "participant_sd", 0.30, "log", "SD of the participant random intercept"),
    e("dwell_time", "residual_sd", 0.40, "log", "Residual SD"),

    e("aesthetic", "harmony_monochromatic", 0.30, "latent", "Monochromatic palette (reference: unstructured palette = 0)"),
    e("aesthetic", "harmony_analogous", 0.50, "latent", "Analogous palette"),
    e("aesthetic", "harmony_complementary", 0.30, "latent", "Complementary palette"),
    e("aesthetic", "harmony_triadic", 0.10, "latent", "Triadic palette"),
    e("aesthetic", "intercept", -0.30, "latent", "Latent appeal of a reference design with an unstructured palette"),
    e("aesthetic", "excess_colours", -0.20, "latent", "Per colour above four"),
    e("aesthetic", "whitespace_quadratic", -0.0008, "latent", "Per squared percentage point of whitespace_pct away from 40"),
    e("aesthetic", "alignment_consistency", 0.80, "latent", "Per unit of alignment_consistency above 0.5"),
    e("aesthetic", "alignment_x_professional", 0.80, "latent", "Extra effect of alignment_consistency for design professionals"),
    e("aesthetic", "excess_typefaces", -0.35, "latent", "Per typeface above two"),
    e("aesthetic", "display_or_script", -0.20, "latent", "Main typeface is a display or script face"),
    e("aesthetic", "visual_complexity", -0.010, "latent", "Per point of visual_complexity above 50"),
    e("aesthetic", "design_sd", 0.45, "latent", "SD of the design random intercept"),
    e("aesthetic", "participant_sd", 0.35, "latent", "SD of the participant scale-use intercept"),
    e("aesthetic", "residual_sd", 0.80, "latent", "Residual SD"),

    e("preference", "aesthetic_latent", 0.60, "latent", "Per SD of the design's latent aesthetic appeal"),
    e("preference", "human_face", 0.25, "latent", "Design shows a human face"),
    e("preference", "saturation", 0.30, "latent", "Per unit of mean_saturation above 0.5"),
    e("preference", "image_text_ratio", 0.50, "latent", "Per unit of image_text_ratio above 0.5"),
    e("preference", "participant_sd", 0.35, "latent", "SD of the participant scale-use intercept"),
    e("preference", "residual_sd", 0.90, "latent", "Residual SD"),

    e("cognitive_load", "intercept", 45, "points", "Mean load for a reference design"),
    e("cognitive_load", "visual_complexity", 0.45, "points", "Per point of visual_complexity above 50"),
    e("cognitive_load", "log_contrast_below_aa", -15, "points", "Per unit of log(effective contrast / 4.5) below 4.5:1 (lower contrast raises load)"),
    e("cognitive_load", "log_word_count", 6, "points", "Per unit of log(word_count / 50)"),
    e("cognitive_load", "visual_literacy", -0.25, "points", "Per point of participant visual_literacy above 50"),
    e("cognitive_load", "participant_sd", 6, "points", "SD of the participant random intercept"),
    e("cognitive_load", "residual_sd", 10, "points", "Residual SD"),

    e("recall_24h", "intercept", -0.40, "logit", "Log-odds of recalling a reference design after 24 hours"),
    e("recall_24h", "human_face", 0.55, "logit", "Design shows a human face"),
    e("recall_24h", "image_text_ratio", 0.80, "logit", "Per unit of image_text_ratio above 0.5"),
    e("recall_24h", "focal_point", 0.40, "logit", "Design has a clear focal point"),
    e("recall_24h", "comprehension", 0.25, "logit", "Per correct answer above 2.5"),
    e("recall_24h", "log_dwell", 0.30, "logit", "Per unit of log(dwell_time_s / 4.5)"),
    e("recall_24h", "visual_complexity", -0.010, "logit", "Per point of visual_complexity above 50"),
    e("recall_24h", "participant_sd", 0.50, "logit", "SD of the participant random intercept"),

    e("engaged", "intercept", -1.60, "logit", "Log-odds of liking, sharing or saving a reference design"),
    e("engaged", "preference", 0.45, "logit", "Per preference point above 4"),
    e("engaged", "social_media", 0.50, "logit", "Design is a social media image"),
    e("engaged", "human_face", 0.30, "logit", "Design shows a human face"),
    e("engaged", "mobile", 0.30, "logit", "Viewed on a mobile phone"),
    e("engaged", "participant_sd", 0.60, "logit", "SD of the participant random intercept")
  )
}

# Look up one generating effect by outcome and term.
effect <- function(effects, outcome, term) {
  value <- effects$value[effects$outcome == outcome & effects$term == term]
  if (length(value) != 1L) stop("Unknown effect: ", outcome, "/", term, call. = FALSE)
  value
}

# Cut points that turn a standard-normal-ish latent variable into a 1-7 rating.
rating_cuts <- c(-2.0, -1.2, -0.45, 0.3, 1.05, 1.85)

# Generators --------------------------------------------------------------
# vc_generate() simulates a whole study: designs (seed), participants (seed + 1) and responses
# (seed + 2). Its defaults reproduce the published files. Pass `effects` (a modified copy of
# vc_true_effects()) to simulate alternative scenarios. The caller's random state is restored.

vc_generate <- function(n_designs = 2000, n_participants = 1000,
                        trials_per_participant = 20, seed = 2026,
                        effects = vc_true_effects()) {
  check_count(n_designs, "n_designs")
  check_count(n_participants, "n_participants")
  check_count(trials_per_participant, "trials_per_participant")
  if (trials_per_participant > n_designs) {
    stop("`trials_per_participant` cannot exceed `n_designs`.", call. = FALSE)
  }
  seeds <- if (is.null(seed)) list(NULL, NULL, NULL) else list(seed, seed + 1, seed + 2)
  designs <- vc_generate_designs(n_designs, seed = seeds[[1]])
  participants <- vc_generate_participants(n_participants, seed = seeds[[2]])
  responses <- vc_generate_responses(designs, participants, trials_per_participant,
                                     seed = seeds[[3]], effects = effects)
  list(designs = designs, participants = participants, responses = responses)
}

vc_generate_designs <- function(n = 2000, seed = 2026) {
  check_count(n, "n")
  with_seed(seed, {
    types <- c("poster", "infographic", "data_chart", "social_media_image", "slide")
    type <- sample(types, n, replace = TRUE, prob = c(0.20, 0.20, 0.20, 0.25, 0.15))

    n_colours <- as.integer(clamp(stats::rpois(n, 3) + 1, 1, 10))
    harmony <- sample(c("monochromatic", "analogous", "complementary", "triadic", "unstructured"),
                      n, replace = TRUE, prob = c(0.15, 0.25, 0.25, 0.15, 0.20))
    harmony[n_colours == 1] <- "monochromatic"
    saturation <- round(stats::rbeta(n, 2.5, 2.5), 2)
    scheme <- sample(c("light", "dark"), n, replace = TRUE, prob = c(0.75, 0.25))
    contrast <- round(clamp(exp(stats::rnorm(n, log(6), 0.65)), 1.2, 21), 2)

    n_typefaces <- as.integer(clamp(stats::rpois(n, 1) + 1, 1, 5))
    typeface <- sample(c("sans_serif", "serif", "slab_serif", "display", "script"),
                       n, replace = TRUE, prob = c(0.50, 0.25, 0.08, 0.12, 0.05))
    base_pt <- c(poster = 14, infographic = 10, data_chart = 10,
                 social_media_image = 16, slide = 24)[type]
    body_pt <- round(clamp(base_pt * exp(stats::rnorm(n, 0, 0.2)), 6, 48))
    line_spacing <- round(clamp(stats::rnorm(n, 1.35, 0.15), 1, 2), 2)

    layout <- sample(c("grid", "modular", "asymmetric", "centred", "freeform"),
                     n, replace = TRUE, prob = c(0.30, 0.20, 0.20, 0.20, 0.10))
    alignment <- round(stats::rbeta(n, ifelse(layout %in% c("grid", "modular"), 6, 3), 2), 2)
    whitespace <- round(clamp(stats::rnorm(n, 38, 12), 5, 75))
    hierarchy <- as.integer(clamp(stats::rpois(n, 2) + 1, 1, 7))
    focal <- stats::rbinom(n, 1, stats::plogis(-0.2 + 0.8 * (hierarchy %in% 2:4) +
                                                 0.6 * (alignment - 0.5))) == 1

    itr_mean <- c(poster = 0.55, infographic = 0.40, data_chart = 0.15,
                  social_media_image = 0.65, slide = 0.35)[type]
    image_text <- round(stats::rbeta(n, itr_mean * 6, (1 - itr_mean) * 6), 2)
    words_median <- c(poster = 40, infographic = 180, data_chart = 30,
                      social_media_image = 15, slide = 35)[type]
    words <- as.integer(clamp(round(exp(stats::rnorm(n, log(words_median), 0.5))), 3, 1200))
    face <- stats::rbinom(n, 1, ifelse(type == "data_chart", 0.05, 0.25 + 0.4 * image_text)) == 1

    chart <- sample(c("bar", "line", "pie", "scatter", "map", "table"),
                    n, replace = TRUE, prob = c(0.30, 0.25, 0.12, 0.13, 0.10, 0.10))
    chart[type != "data_chart"] <- NA
    data_ink <- round(stats::rbeta(n, 5, 3), 2)
    data_ink[!type %in% c("data_chart", "infographic")] <- NA
    alt_text <- stats::rbinom(n, 1, 0.35) == 1

    complexity <- round(100 * stats::plogis(0.35 * (n_colours - 4) + 0.8 * log(words / 50) -
                                              0.04 * (whitespace - 38) + 0.4 * (n_typefaces - 2) +
                                              0.25 * (hierarchy - 3)), 1)

    data.frame(
      design_id = sprintf("D%04d", seq_len(n)),
      artefact_type = type,
      n_colours = n_colours,
      colour_harmony = harmony,
      mean_saturation = saturation,
      colour_scheme = scheme,
      contrast_ratio = contrast,
      wcag_aa_contrast = contrast >= ifelse(body_pt >= 18, 3, 4.5),
      n_typefaces = n_typefaces,
      typeface_class = typeface,
      body_text_pt = body_pt,
      line_spacing = line_spacing,
      layout = layout,
      alignment_consistency = alignment,
      whitespace_pct = whitespace,
      hierarchy_levels = hierarchy,
      focal_point = focal,
      image_text_ratio = image_text,
      word_count = words,
      human_face = face,
      chart_type = chart,
      data_ink_ratio = data_ink,
      alt_text = alt_text,
      visual_complexity = complexity,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })
}

vc_generate_participants <- function(n = 1000, seed = 2027) {
  check_count(n, "n")
  with_seed(seed, {
    age <- sample(c("18-24", "25-34", "35-44", "45-54", "55-64", "65+"), n, replace = TRUE,
                  prob = c(0.22, 0.22, 0.18, 0.15, 0.13, 0.10))
    expertise <- sample(c("none", "student", "professional"), n, replace = TRUE,
                        prob = c(0.55, 0.30, 0.15))
    literacy <- round(clamp(stats::rnorm(n, 50 + c(none = -5, student = 5, professional = 15)[expertise], 14),
                            0, 100))
    vision <- sample(c("typical", "deutan", "protan", "tritan"), n, replace = TRUE,
                     prob = c(0.955, 0.030, 0.012, 0.003))
    low_vision <- stats::rbinom(n, 1, ifelse(age %in% c("55-64", "65+"), 0.08, 0.02)) == 1
    device <- sample(c("desktop", "mobile", "tablet"), n, replace = TRUE, prob = c(0.45, 0.45, 0.10))
    data.frame(
      participant_id = sprintf("P%04d", seq_len(n)),
      age_group = age,
      design_expertise = expertise,
      visual_literacy = literacy,
      colour_vision = vision,
      low_vision = low_vision,
      device = device,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  })
}

vc_generate_responses <- function(designs, participants, trials_per_participant = 20,
                                  seed = 2028, effects = vc_true_effects()) {
  check_count(trials_per_participant, "trials_per_participant")
  nd <- nrow(designs)
  np <- nrow(participants)
  k <- trials_per_participant
  if (k > nd) stop("`trials_per_participant` cannot exceed the number of designs.", call. = FALSE)
  b <- function(outcome, term) effect(effects, outcome, term)

  with_seed(seed, {
    di <- as.vector(vapply(seq_len(np), function(i) sample.int(nd, k), integer(k)))
    pidx <- rep(seq_len(np), each = k)
    n <- length(di)
    d <- designs[di, , drop = FALSE]
    p <- participants[pidx, , drop = FALSE]

    # Random intercepts: one draw per design or participant, shared by its rows.
    re <- function(sd, size, index) stats::rnorm(size, 0, sd)[index]
    u_comp <- re(b("comprehension", "design_sd"), nd, di)
    v_comp <- re(b("comprehension", "participant_sd"), np, pidx)
    u_aes <- re(b("aesthetic", "design_sd"), nd, di)
    v_aes <- re(b("aesthetic", "participant_sd"), np, pidx)
    v_pref <- re(b("preference", "participant_sd"), np, pidx)
    v_dwell <- re(b("dwell_time", "participant_sd"), np, pidx)
    v_load <- re(b("cognitive_load", "participant_sd"), np, pidx)
    v_recall <- re(b("recall_24h", "participant_sd"), np, pidx)
    v_eng <- re(b("engaged", "participant_sd"), np, pidx)

    # Contrast as experienced by the participant.
    red_green <- p$colour_vision %in% c("deutan", "protan")
    cvd_hit <- (red_green & d$colour_harmony %in% c("complementary", "triadic")) |
      (p$colour_vision == "tritan" & d$colour_harmony == "triadic")
    mult <- ifelse(cvd_hit, b("effective_contrast", "cvd_multiplier"), 1) *
      ifelse(p$low_vision, b("effective_contrast", "low_vision_multiplier"), 1)
    lc <- log((1 + (d$contrast_ratio - 1) * mult) / 4.5)
    below <- pmin(lc, 0)
    above <- pmax(lc, 0)

    cx <- d$visual_complexity - 50
    lw <- log(d$word_count / 50)
    vl <- p$visual_literacy - 50
    mobile <- p$device == "mobile"
    dink <- ifelse(is.na(d$data_ink_ratio), 0, d$data_ink_ratio - 0.6)
    pie <- !is.na(d$chart_type) & d$chart_type == "pie"

    eta_comp <- b("comprehension", "intercept") +
      b("comprehension", "log_contrast_below_aa") * below +
      b("comprehension", "log_contrast_above_aa") * above +
      b("comprehension", "hierarchy_quadratic") * (d$hierarchy_levels - 3)^2 +
      b("comprehension", "log_word_count") * lw +
      b("comprehension", "visual_complexity") * cx +
      b("comprehension", "focal_point") * d$focal_point +
      b("comprehension", "visual_literacy") * vl +
      b("comprehension", "data_ink_ratio") * dink +
      b("comprehension", "pie_chart") * pie +
      b("comprehension", "small_text_mobile") * pmax(12 - d$body_text_pt, 0) * mobile +
      u_comp + v_comp
    comprehension <- stats::rbinom(n, 5, stats::plogis(eta_comp))

    log_ttff <- b("time_to_first_fixation", "intercept") +
      b("time_to_first_fixation", "log_contrast") * lc +
      b("time_to_first_fixation", "human_face") * d$human_face +
      b("time_to_first_fixation", "focal_point") * d$focal_point +
      b("time_to_first_fixation", "saturation") * (d$mean_saturation - 0.5) +
      b("time_to_first_fixation", "visual_complexity") * cx +
      stats::rnorm(n, 0, b("time_to_first_fixation", "residual_sd"))

    harmony_term <- vapply(d$colour_harmony, function(h) {
      if (h == "unstructured") 0 else b("aesthetic", paste0("harmony_", h))
    }, numeric(1), USE.NAMES = FALSE)
    align <- d$alignment_consistency - 0.5
    aes_design <- b("aesthetic", "intercept") + harmony_term +
      b("aesthetic", "excess_colours") * pmax(d$n_colours - 4, 0) +
      b("aesthetic", "whitespace_quadratic") * (d$whitespace_pct - 40)^2 +
      b("aesthetic", "alignment_consistency") * align +
      b("aesthetic", "excess_typefaces") * pmax(d$n_typefaces - 2, 0) +
      b("aesthetic", "display_or_script") * (d$typeface_class %in% c("display", "script")) +
      b("aesthetic", "visual_complexity") * cx +
      u_aes
    aes_latent <- aes_design + v_aes +
      b("aesthetic", "alignment_x_professional") * align * (p$design_expertise == "professional") +
      stats::rnorm(n, 0, b("aesthetic", "residual_sd"))

    pref_latent <- b("preference", "aesthetic_latent") * aes_design +
      b("preference", "human_face") * d$human_face +
      b("preference", "saturation") * (d$mean_saturation - 0.5) +
      b("preference", "image_text_ratio") * (d$image_text_ratio - 0.5) +
      v_pref + stats::rnorm(n, 0, b("preference", "residual_sd"))
    preference <- to_rating(pref_latent)

    log_dwell <- b("dwell_time", "intercept") +
      b("dwell_time", "log_word_count") * lw +
      b("dwell_time", "visual_complexity") * cx +
      b("dwell_time", "mobile") * mobile +
      b("dwell_time", "aesthetic_latent") * aes_design +
      v_dwell + stats::rnorm(n, 0, b("dwell_time", "residual_sd"))
    dwell <- round(clamp(exp(log_dwell), 0.3, 120), 1)

    load <- b("cognitive_load", "intercept") +
      b("cognitive_load", "visual_complexity") * cx +
      b("cognitive_load", "log_contrast_below_aa") * below +
      b("cognitive_load", "log_word_count") * lw +
      b("cognitive_load", "visual_literacy") * vl +
      v_load + stats::rnorm(n, 0, b("cognitive_load", "residual_sd"))

    eta_recall <- b("recall_24h", "intercept") +
      b("recall_24h", "human_face") * d$human_face +
      b("recall_24h", "image_text_ratio") * (d$image_text_ratio - 0.5) +
      b("recall_24h", "focal_point") * d$focal_point +
      b("recall_24h", "comprehension") * (comprehension - 2.5) +
      b("recall_24h", "log_dwell") * log(dwell / 4.5) +
      b("recall_24h", "visual_complexity") * cx +
      v_recall

    eta_eng <- b("engaged", "intercept") +
      b("engaged", "preference") * (preference - 4) +
      b("engaged", "social_media") * (d$artefact_type == "social_media_image") +
      b("engaged", "human_face") * d$human_face +
      b("engaged", "mobile") * mobile +
      v_eng

    # Trial order is random within each participant.
    trial <- as.vector(vapply(seq_len(np), function(i) sample.int(k), integer(k)))

    out <- data.frame(
      response_id = sprintf("R%06d", seq_len(n)),
      participant_id = p$participant_id,
      design_id = d$design_id,
      trial = trial,
      time_to_first_fixation_ms = as.integer(round(clamp(exp(log_ttff), 80, 10000))),
      dwell_time_s = dwell,
      comprehension_score = as.integer(comprehension),
      aesthetic_rating = to_rating(aes_latent),
      preference_rating = preference,
      cognitive_load = as.integer(round(clamp(load, 0, 100))),
      recall_24h = stats::rbinom(n, 1, stats::plogis(eta_recall)) == 1,
      engaged = stats::rbinom(n, 1, stats::plogis(eta_eng)) == 1,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
    out <- out[order(pidx, out$trial), , drop = FALSE]
    out$response_id <- sprintf("R%06d", seq_len(n))
    rownames(out) <- NULL
    out
  })
}

# Internal helpers --------------------------------------------------------

# Evaluate `code` with a fixed, version-stable RNG, then restore the caller's RNG.
with_seed <- function(seed, code) {
  if (is.null(seed)) return(code)
  genv <- globalenv()
  had_seed <- exists(".Random.seed", envir = genv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = genv, inherits = FALSE)
  old_kind <- RNGkind()
  on.exit({
    RNGkind(old_kind[1], old_kind[2], old_kind[3])
    if (had_seed) assign(".Random.seed", old_seed, envir = genv)
    else rm(".Random.seed", envir = genv)
  }, add = TRUE)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  code
}

clamp <- function(x, lo, hi) pmin(pmax(x, lo), hi)

to_rating <- function(latent) as.integer(findInterval(latent, rating_cuts) + 1L)

check_count <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 1 || x != round(x)) {
    stop("`", name, "` must be a single positive whole number.", call. = FALSE)
  }
}

# Codebook ----------------------------------------------------------------
# vc_codebook() returns one row per variable: table, type, unit, allowed values, role, description.
# role is identifier, attribute (simulated input), derived (computed) or outcome (simulated response).

vc_codebook <- function() {
  v <- function(table, variable, type, unit, values, role, description) {
    data.frame(table = table, variable = variable, type = type, unit = unit,
               values = values, role = role, description = description,
               stringsAsFactors = FALSE)
  }
  rbind(
    v("designs", "design_id", "character", "", "D0001-D2000", "identifier", "Design identifier"),
    v("designs", "artefact_type", "character", "", "poster; infographic; data_chart; social_media_image; slide", "attribute", "Kind of visual artefact"),
    v("designs", "n_colours", "integer", "colours", "1-10", "attribute", "Number of distinct colours in the palette"),
    v("designs", "colour_harmony", "character", "", "monochromatic; analogous; complementary; triadic; unstructured", "attribute", "Colour harmony scheme of the palette"),
    v("designs", "mean_saturation", "numeric", "proportion", "0-1", "attribute", "Mean saturation of the palette"),
    v("designs", "colour_scheme", "character", "", "light; dark", "attribute", "Light text-on-dark or dark text-on-light background"),
    v("designs", "contrast_ratio", "numeric", "ratio (x:1)", "1.2-21", "attribute", "WCAG contrast ratio between body text and its background"),
    v("designs", "wcag_aa_contrast", "logical", "", "TRUE; FALSE", "derived", "Meets WCAG 2 AA text contrast: 4.5:1, or 3:1 when body_text_pt is 18 or more"),
    v("designs", "n_typefaces", "integer", "typefaces", "1-5", "attribute", "Number of typeface families used"),
    v("designs", "typeface_class", "character", "", "sans_serif; serif; slab_serif; display; script", "attribute", "Classification of the main typeface"),
    v("designs", "body_text_pt", "numeric", "points", "6-48", "attribute", "Body text size at intended viewing size"),
    v("designs", "line_spacing", "numeric", "multiple of text size", "1-2", "attribute", "Line spacing (leading) of body text"),
    v("designs", "layout", "character", "", "grid; modular; asymmetric; centred; freeform", "attribute", "Layout structure"),
    v("designs", "alignment_consistency", "numeric", "proportion", "0-1", "attribute", "Share of elements aligned to a common grid or axis"),
    v("designs", "whitespace_pct", "numeric", "percent of area", "5-75", "attribute", "Area left empty"),
    v("designs", "hierarchy_levels", "integer", "levels", "1-7", "attribute", "Number of distinct typographic or visual hierarchy levels"),
    v("designs", "focal_point", "logical", "", "TRUE; FALSE", "attribute", "Design has one clear entry point that draws the eye"),
    v("designs", "image_text_ratio", "numeric", "proportion", "0-1", "attribute", "Share of the content area occupied by imagery rather than text"),
    v("designs", "word_count", "integer", "words", "3-1200", "attribute", "Number of words of text"),
    v("designs", "human_face", "logical", "", "TRUE; FALSE", "attribute", "Design shows at least one human face"),
    v("designs", "chart_type", "character", "", "bar; line; pie; scatter; map; table; NA", "attribute", "Chart type (data charts only; NA otherwise)"),
    v("designs", "data_ink_ratio", "numeric", "proportion", "0-1; NA", "attribute", "Share of ink used for data (infographics and data charts only; NA otherwise)"),
    v("designs", "alt_text", "logical", "", "TRUE; FALSE", "attribute", "A text alternative is provided"),
    v("designs", "visual_complexity", "numeric", "index", "0-100", "derived", "Index computed from colours, words, whitespace, typefaces and hierarchy levels (formula in DATA_DESCRIPTOR.md)"),

    v("participants", "participant_id", "character", "", "P0001-P1000", "identifier", "Participant identifier (fictitious person)"),
    v("participants", "age_group", "character", "years", "18-24; 25-34; 35-44; 45-54; 55-64; 65+", "attribute", "Age band"),
    v("participants", "design_expertise", "character", "", "none; student; professional", "attribute", "Training or work in design"),
    v("participants", "visual_literacy", "numeric", "points", "0-100", "attribute", "Score on a fictitious visual literacy test"),
    v("participants", "colour_vision", "character", "", "typical; deutan; protan; tritan", "attribute", "Colour vision (deutan, protan and tritan are colour vision deficiencies)"),
    v("participants", "low_vision", "logical", "", "TRUE; FALSE", "attribute", "Participant has low vision"),
    v("participants", "device", "character", "", "desktop; mobile; tablet", "attribute", "Device used to view the designs"),

    v("responses", "response_id", "character", "", "R000001-R020000", "identifier", "Response identifier"),
    v("responses", "participant_id", "character", "", "P0001-P1000", "identifier", "Participant who responded (key to participants)"),
    v("responses", "design_id", "character", "", "D0001-D2000", "identifier", "Design shown (key to designs)"),
    v("responses", "trial", "integer", "position", "1-20", "attribute", "Position of the design in the participant's sequence"),
    v("responses", "time_to_first_fixation_ms", "integer", "milliseconds", "80-10000", "outcome", "Simulated time until the gaze first lands on the key message"),
    v("responses", "dwell_time_s", "numeric", "seconds", "0.3-120", "outcome", "Simulated time spent looking at the design"),
    v("responses", "comprehension_score", "integer", "correct answers", "0-5", "outcome", "Correct answers to five comprehension questions"),
    v("responses", "aesthetic_rating", "integer", "Likert", "1-7", "outcome", "Perceived visual appeal (1 = very unappealing, 7 = very appealing)"),
    v("responses", "preference_rating", "integer", "Likert", "1-7", "outcome", "Would choose this design over others (1 = not at all, 7 = definitely)"),
    v("responses", "cognitive_load", "integer", "points", "0-100", "outcome", "Perceived mental effort"),
    v("responses", "recall_24h", "logical", "", "TRUE; FALSE", "outcome", "Recalled the design's key message after 24 hours"),
    v("responses", "engaged", "logical", "", "TRUE; FALSE", "outcome", "Liked, shared or saved the design"),

    v("images", "design_id", "character", "", "D0001-D2000", "identifier", "Design shown in the image (key to designs)"),
    v("images", "image_file", "character", "", "images/D0001.png-images/D2000.png", "identifier", "Path of the PNG image, relative to the dataset root"),
    v("images", "width_px", "numeric", "pixels", "450-800", "derived", "Image width; set by artefact_type"),
    v("images", "height_px", "numeric", "pixels", "450-800", "derived", "Image height; set by artefact_type"),
    v("images", "background_colour", "character", "hex sRGB", "#RRGGBB", "derived", "Background colour drawn"),
    v("images", "text_colour", "character", "hex sRGB", "#RRGGBB", "derived", "Body text colour drawn"),
    v("images", "rendered_contrast", "numeric", "ratio (x:1)", "1.2-21", "derived", "WCAG contrast ratio between text_colour and background_colour as drawn (matches contrast_ratio up to 8-bit rounding)"),
    v("images", "palette", "character", "hex sRGB", "space-separated #RRGGBB values", "derived", "Palette colours drawn, one per colour in n_colours"),
    v("images", "words_drawn", "integer", "words", "0-1200", "derived", "Words of pseudo-text that fitted in the image (word_count or fewer)"),
    v("images", "md5", "character", "", "32 hex digits", "derived", "MD5 checksum of the PNG file")
  )
}
