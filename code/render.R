# SynthVisCom renderer: draws one synthetic PNG image per design from its variables.
# Base R only (grid and grDevices, with the cairo PNG device). Source code/generator.R first.
# ALL IMAGES ARE SYNTHETIC: abstract compositions, pseudo-text and schematic faces, not real designs.
# Code licence: MIT (see LICENSE).
#
# What each variable controls:
#   artefact_type          canvas proportions and kind of content (chart, infographic, slide bullets...)
#   n_colours, colour_harmony, mean_saturation   the palette (HCL hues, chroma from saturation)
#   colour_scheme, contrast_ratio                background and text colours, solved to hit the WCAG ratio
#   n_typefaces, typeface_class, body_text_pt, line_spacing   type families, faces, sizes, leading
#   layout, alignment_consistency, whitespace_pct              placement, jitter and margins
#   hierarchy_levels       number of distinct text sizes (title, subtitle, headings, body)
#   focal_point            one dominant element vs many similar ones
#   image_text_ratio       share of the content area given to imagery
#   word_count             words of pseudo-text (the manifest records how many fitted)
#   human_face             a schematic face in the image area
#   chart_type, data_ink_ratio   the chart drawn, and how much non-data decoration surrounds it

# Canvas size in pixels (longest side 800) for each artefact type.
vc_image_size <- function(type) {
  sizes <- list(poster = c(566, 800), infographic = c(450, 800), data_chart = c(800, 600),
                social_media_image = c(800, 800), slide = c(800, 450))
  sizes[[type]]
}

# Render every design to images/<design_id>.png and return the image manifest.
vc_render_images <- function(designs, dir = "images", seed = 3000) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  rows <- lapply(seq_len(nrow(designs)), function(i) {
    path <- file.path(dir, paste0(designs$design_id[i], ".png"))
    info <- with_seed(seed + i, render_design(designs[i, , drop = FALSE], path))
    data.frame(design_id = designs$design_id[i], image_file = path,
               width_px = info$size[1], height_px = info$size[2],
               background_colour = info$bg, text_colour = info$fg,
               rendered_contrast = round(wcag_contrast(info$fg, info$bg), 2),
               palette = paste(info$palette, collapse = " "),
               words_drawn = info$words_drawn, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

# Colour -------------------------------------------------------------------

srgb_to_linear <- function(v) ifelse(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055)^2.4)
linear_to_srgb <- function(l) ifelse(l <= 0.0031308, 12.92 * l, 1.055 * l^(1 / 2.4) - 0.055)

wcag_luminance <- function(hex) {
  lin <- srgb_to_linear(grDevices::col2rgb(hex) / 255)
  as.vector(c(0.2126, 0.7152, 0.0722) %*% lin)
}

wcag_contrast <- function(a, b) {
  la <- wcag_luminance(a)
  lb <- wcag_luminance(b)
  (pmax(la, lb) + 0.05) / (pmin(la, lb) + 0.05)
}

grey <- function(v) grDevices::rgb(v, v, v, maxColorValue = 255)

# Background tinted with the palette hue; text a neutral grey whose luminance gives the target ratio.
contrast_pair <- function(ratio, scheme, hue) {
  if (scheme == "light") {
    bg <- grDevices::hcl(hue, stats::runif(1, 4, 14), stats::runif(1, 90, 98))
    target <- (wcag_luminance(bg) + 0.05) / ratio - 0.05
    if (target < 0) {
      bg <- "#FFFFFF"
      target <- 1.05 / ratio - 0.05
    }
  } else {
    bg <- grDevices::hcl(hue, stats::runif(1, 8, 20), stats::runif(1, 8, 18))
    target <- ratio * (wcag_luminance(bg) + 0.05) - 0.05
    if (target > 1) {
      bg <- "#000000"
      target <- 0.05 * ratio - 0.05
    }
  }
  v <- linear_to_srgb(clamp(target, 0, 1)) * 255
  options <- unique(clamp(c(floor(v), ceiling(v)), 0, 255))
  fg <- grey(options[which.min(abs(wcag_contrast(grey(options), bg) - ratio))])
  list(bg = bg, fg = fg)
}

make_palette <- function(n, harmony, saturation, hue) {
  hues <- switch(harmony,
    monochromatic = rep(hue, n),
    analogous = hue + seq(-30, 30, length.out = n),
    complementary = hue + rep(c(0, 180), length.out = n),
    triadic = hue + rep(c(0, 120, 240), length.out = n),
    unstructured = stats::runif(n, 0, 360))
  lum <- if (harmony == "monochromatic") seq(35, 80, length.out = n) else stats::runif(n, 40, 75)
  chroma <- clamp(10 + 90 * saturation + stats::rnorm(n, 0, 6), 0, 100)
  grDevices::hcl(hues %% 360, chroma, lum, fixup = TRUE)
}

# Text ---------------------------------------------------------------------

syllables <- c("lo", "rem", "ip", "sum", "do", "lor", "sit", "a", "met", "con", "sec", "te",
               "tur", "vi", "sa", "nu", "mi", "ra", "ta", "pe", "ko", "li", "ve", "na", "mo", "ser")

pseudo_words <- function(n) {
  if (n <= 0) return(character())
  vapply(seq_len(n), function(i) paste(sample(syllables, sample(1:4, 1, prob = c(3, 4, 2, 1)),
                                              replace = TRUE), collapse = ""), "")
}

# Approximate advance width of one character as a share of the font size.
char_width <- function(family, face) {
  base <- c(sans = 0.52, serif = 0.48, mono = 0.6)[[family]]
  if (face %in% c("bold", "bold.italic")) base * 1.08 else base
}

wrap_words <- function(words, max_chars) {
  lines <- character()
  current <- ""
  for (w in words) {
    if (!nzchar(current)) current <- w
    else if (nchar(current) + 1 + nchar(w) <= max_chars) current <- paste(current, w)
    else {
      lines <- c(lines, current)
      current <- w
    }
  }
  if (nzchar(current)) lines <- c(lines, current)
  lines
}

# Draw text items top-down inside a rectangle; returns the items (and words) that did not fit.
draw_text <- function(items, rect, just, colour, lineheight, jitter_sd) {
  y <- rect[2] + rect[4]
  drawn <- 0
  while (length(items)) {
    it <- items[[1]]
    max_chars <- max(4, floor(rect[3] / (it$size * char_width(it$family, it$face))))
    lines <- wrap_words(it$words, max_chars)
    dx <- stats::rnorm(1, 0, jitter_sd)
    step <- it$size * lineheight
    x <- if (just == "centre") rect[1] + rect[3] / 2 + dx else rect[1] + dx
    fitted <- 0
    for (ln in lines) {
      if (y - step < rect[2]) break
      grid::grid.text(ln, x, y - it$size, just = c(if (just == "centre") "centre" else "left", "bottom"),
                      default.units = "native",
                      gp = grid::gpar(fontsize = it$size, fontfamily = it$family,
                                      fontface = it$face, col = colour))
      y <- y - step
      fitted <- fitted + 1
    }
    used <- if (fitted == length(lines)) length(it$words) else
      length(unlist(strsplit(paste(lines[seq_len(fitted)], collapse = " "), " ")))
    if (fitted == 0) used <- 0
    drawn <- drawn + used
    if (used < length(it$words)) {
      it$words <- it$words[-seq_len(used)]
      items[[1]] <- it
      return(list(items = items, drawn = drawn))
    }
    items <- items[-1]
    y <- y - it$size * 0.5
  }
  list(items = items, drawn = drawn)
}

# Imagery ------------------------------------------------------------------

rect_shape <- function(x, y, w, h, fill, col = NA, lwd = 1) {
  grid::grid.rect(x, y, w, h, just = c("left", "bottom"), default.units = "native",
                  gp = grid::gpar(fill = fill, col = col, lwd = lwd))
}

draw_face <- function(cx, cy, r, accent) {
  skin <- sample(c("#8D5524", "#C68642", "#E0AC69", "#F1C27D", "#FFDBAC"), 1)
  hair <- sample(c("#1B1B1B", "#2C1B10", "#4B3621", "#A55728", "#B7A69E"), 1)
  grid::grid.circle(cx, cy - r * 1.55, r * 1.1, default.units = "native",
                    gp = grid::gpar(fill = accent, col = NA))
  grid::grid.circle(cx, cy + r * 0.12, r * 1.04, default.units = "native", gp = grid::gpar(fill = hair, col = NA))
  grid::grid.circle(cx, cy, r, default.units = "native", gp = grid::gpar(fill = skin, col = NA))
  for (s in c(-1, 1)) {
    grid::grid.circle(cx + s * r * 0.35, cy + r * 0.15, r * 0.09, default.units = "native",
                      gp = grid::gpar(fill = "#1B1B1B", col = NA))
  }
  t <- seq(pi * 1.15, pi * 1.85, length.out = 12)
  grid::grid.lines(cx + r * 0.45 * cos(t), cy - r * 0.05 + r * 0.45 * sin(t), default.units = "native",
                   gp = grid::gpar(col = "#5A2A27", lwd = max(1, r / 18)))
}

draw_composition <- function(rect, palette, focal, face) {
  x <- rect[1]; y <- rect[2]; w <- rect[3]; h <- rect[4]
  rect_shape(x, y, w, h, fill = palette[1])
  shape <- function(px, py, size, fill) {
    kind <- sample(c("circle", "square", "triangle"), 1)
    if (kind == "circle") {
      grid::grid.circle(px, py, size / 2, default.units = "native", gp = grid::gpar(fill = fill, col = NA))
    } else if (kind == "square") {
      grid::grid.rect(px, py, size, size, default.units = "native", gp = grid::gpar(fill = fill, col = NA))
    } else {
      grid::grid.polygon(px + size * c(-0.5, 0.5, 0), py + size * c(-0.43, -0.43, 0.43),
                         default.units = "native", gp = grid::gpar(fill = fill, col = NA))
    }
  }
  others <- if (length(palette) > 1) palette[-1] else palette
  m <- min(w, h)
  if (focal) {
    for (k in seq_len(sample(2:4, 1))) {
      shape(x + stats::runif(1) * w, y + stats::runif(1) * h, m * stats::runif(1, 0.08, 0.16), sample(others, 1))
    }
    if (!face) {
      grid::grid.circle(x + w * stats::runif(1, 0.4, 0.6), y + h * stats::runif(1, 0.4, 0.6), m * 0.33,
                        default.units = "native", gp = grid::gpar(fill = others[1], col = NA))
    }
  } else {
    for (k in seq_len(sample(9:16, 1))) {
      shape(x + stats::runif(1) * w, y + stats::runif(1) * h, m * stats::runif(1, 0.12, 0.2), sample(others, 1))
    }
  }
  if (face) draw_face(x + w / 2, y + h * 0.52, m * (if (focal) 0.26 else 0.17), others[length(others)])
}

draw_chart <- function(rect, chart, palette, fg, bg, data_ink, body) {
  x <- rect[1]; y <- rect[2]; w <- rect[3]; h <- rect[4]
  junk <- 1 - data_ink
  gp_text <- grid::gpar(fontsize = max(6, body * 0.8), col = fg)
  if (junk > 0.35) {
    rect_shape(x, y, w, h, fill = grDevices::adjustcolor(palette[1], alpha.f = 0.25 + 0.4 * junk),
               col = fg, lwd = 1 + 3 * junk)
  }
  px <- x + w * 0.12; py <- y + h * 0.12; pw <- w * 0.82; ph <- h * 0.8
  if (chart %in% c("bar", "line", "scatter")) {
    n_grid <- if (junk > 0.25) round(4 + 8 * junk) else 0
    for (g in seq_len(n_grid)) {
      gy <- py + ph * g / (n_grid + 1)
      grid::grid.lines(c(px, px + pw), c(gy, gy), default.units = "native",
                       gp = grid::gpar(col = grDevices::adjustcolor(fg, 0.5), lwd = 0.5 + 2 * junk))
    }
    grid::grid.lines(c(px, px, px + pw), c(py + ph, py, py), default.units = "native",
                     gp = grid::gpar(col = fg, lwd = 1))
  }
  cols <- rep(palette, length.out = 8)
  if (chart == "bar") {
    k <- sample(4:7, 1)
    vals <- stats::runif(k, 0.2, 1)
    bw <- pw / k
    for (i in seq_len(k)) {
      if (junk > 0.4) rect_shape(px + (i - 0.9) * bw + 4, py - 4, bw * 0.7, ph * vals[i], fill = "#00000040")
      rect_shape(px + (i - 0.9) * bw, py, bw * 0.7, ph * vals[i], fill = if (junk > 0.5) cols[i] else cols[1],
                 col = if (junk > 0.5) fg else NA, lwd = 1 + 2 * junk)
      grid::grid.text(sprintf("%d", round(vals[i] * 100)), px + (i - 0.55) * bw, py - body,
                      default.units = "native", gp = gp_text)
    }
  } else if (chart == "line") {
    for (s in 1:2) {
      v <- cumsum(stats::rnorm(12, 0.05, 0.12))
      v <- (v - min(v)) / (diff(range(v)) + 1e-9)
      grid::grid.lines(px + pw * (0:11) / 11, py + ph * (0.1 + 0.8 * v), default.units = "native",
                       gp = grid::gpar(col = cols[s], lwd = 2 + 3 * junk))
      if (junk > 0.4) grid::grid.points(px + pw * (0:11) / 11, py + ph * (0.1 + 0.8 * v), pch = 19,
                                        default.units = "native", gp = grid::gpar(col = cols[s], cex = 0.8))
    }
  } else if (chart == "scatter") {
    g <- sample(1:2, 40, replace = TRUE)
    grid::grid.points(px + pw * stats::runif(40, 0.05, 0.95), py + ph * stats::runif(40, 0.05, 0.95),
                      pch = 19, default.units = "native",
                      gp = grid::gpar(col = cols[g], cex = 0.7 + 0.8 * junk))
  } else if (chart == "pie") {
    k <- sample(4:6, 1)
    p <- cumsum(c(0, prop.table(stats::runif(k, 0.3, 1))))
    cx <- x + w / 2; cy <- y + h / 2; r <- min(w, h) * 0.38
    for (i in seq_len(k)) {
      t <- seq(2 * pi * p[i], 2 * pi * p[i + 1], length.out = 30)
      grid::grid.polygon(c(cx, cx + r * cos(t)), c(cy, cy + r * sin(t)), default.units = "native",
                         gp = grid::gpar(fill = cols[i], col = if (junk > 0.4) fg else bg, lwd = 1 + 2 * junk))
    }
  } else if (chart == "map") {
    ramp <- grDevices::colorRampPalette(c(bg, palette[length(palette)]))(6)
    nx <- 8; ny <- 6
    for (i in seq_len(nx)) for (j in seq_len(ny)) {
      if (stats::runif(1) < 0.15) next
      rect_shape(px + (i - 1) * pw / nx, py + (j - 1) * ph / ny, pw / nx * 0.94, ph / ny * 0.94,
                 fill = sample(ramp[-1], 1), col = if (junk > 0.4) fg else NA)
    }
  } else if (chart == "table") {
    nr <- 6; nc <- 4
    for (i in 0:nr) {
      if (junk > 0.3 || i %in% c(0, 1, nr)) {
        grid::grid.lines(c(px, px + pw), py + ph * (1 - i / nr) * c(1, 1), default.units = "native",
                         gp = grid::gpar(col = fg, lwd = if (i == 1) 1.5 else 0.5 + junk))
      }
      if (i < nr) for (j in seq_len(nc)) {
        label <- if (i == 0) pseudo_words(1) else sprintf("%.1f", stats::runif(1, 0, 99))
        grid::grid.text(label, px + pw * (j - 0.5) / nc, py + ph * (1 - (i + 0.5) / nr),
                        default.units = "native",
                        gp = grid::gpar(fontsize = max(6, body * 0.9), col = fg,
                                        fontface = if (i == 0) "bold" else "plain"))
      }
    }
  }
}

draw_infographic <- function(rect, palette, fg, data_ink, body, face) {
  x <- rect[1]; y <- rect[2]; w <- rect[3]; h <- rect[4]
  accent <- palette[length(palette)]
  if (data_ink < 0.6) rect_shape(x, y, w, h, fill = grDevices::adjustcolor(palette[1], 0.35))
  grid::grid.text(sprintf("%d%%", sample(12:94, 1)), x + w * 0.05, y + h * 0.78, just = "left",
                  default.units = "native",
                  gp = grid::gpar(fontsize = min(h * 0.25, w * 0.18), fontface = "bold", col = accent))
  n_icons <- 10
  k <- sample(2:8, 1)
  s <- w / (n_icons + 1)
  for (i in seq_len(n_icons)) {
    col <- if (i <= k) accent else grDevices::adjustcolor(fg, 0.3)
    ix <- x + i * s
    grid::grid.circle(ix, y + h * 0.42, s * 0.18, default.units = "native", gp = grid::gpar(fill = col, col = NA))
    rect_shape(ix - s * 0.22, y + h * 0.18, s * 0.44, h * 0.17, fill = col)
  }
  if (face) draw_face(x + w * 0.82, y + h * 0.8, min(w, h) * 0.11, palette[1])
}

# One design ---------------------------------------------------------------

render_design <- function(d, path) {
  size <- vc_image_size(d$artefact_type)
  W <- size[1]; H <- size[2]
  hue <- stats::runif(1, 0, 360)
  palette <- make_palette(d$n_colours, d$colour_harmony, d$mean_saturation, hue)
  cp <- contrast_pair(d$contrast_ratio, d$colour_scheme, hue)

  # Typefaces: the main class sets title and body; extra families go to subtitles and headings.
  main <- switch(d$typeface_class,
    sans_serif = list(family = "sans", face = "plain", title_face = "bold"),
    serif = list(family = "serif", face = "plain", title_face = "bold"),
    slab_serif = list(family = "serif", face = "plain", title_face = "bold"),
    display = list(family = "sans", face = "plain", title_face = "bold"),
    script = list(family = "serif", face = "italic", title_face = "bold.italic"))
  pool <- setdiff(c("sans", "serif", "mono"), main$family)
  families <- c(main$family, rep(sample(pool), length.out = max(0, d$n_typefaces - 1)))
  fam <- function(level) families[min(level, length(families))]
  extra_faces <- c("plain", "bold", "italic", "bold.italic")
  face_for <- function(level) if (level <= length(families)) "plain" else extra_faces[(level %% 4) + 1]

  body <- d$body_text_pt
  levels <- d$hierarchy_levels
  sizes <- body * 1.45^(rev(seq_len(levels)) - 1)
  m <- max(0.03, (1 - sqrt(1 - d$whitespace_pct / 100)) / 2)
  x0 <- m * W; y0 <- m * H; cw <- W * (1 - 2 * m); ch <- H * (1 - 2 * m)
  sizes[1] <- min(sizes[1], ch / 7, cw / 9)
  sizes <- pmax(sizes, body)
  gap <- body
  jitter <- (1 - d$alignment_consistency) * 0.04 * W

  # Words: title, subtitle, headings and body share word_count.
  n_title <- min(d$word_count, sample(2:6, 1))
  n_sub <- if (levels >= 2) min(d$word_count - n_title, sample(3:8, 1)) else 0
  n_rest <- max(0, d$word_count - n_title - n_sub)
  title <- pseudo_words(n_title)
  if (d$typeface_class == "display") title <- toupper(title)
  items <- list()
  if (n_sub > 0) items[[1]] <- list(words = pseudo_words(n_sub), size = sizes[2], family = fam(2), face = face_for(2))
  heading_levels <- if (levels >= 4) 3:(levels - 1) else integer()
  n_par <- max(1, length(heading_levels) + 1, ceiling(n_rest / 60))
  par_words <- split(pseudo_words(n_rest), rep(seq_len(n_par), length.out = n_rest))
  for (p in seq_along(par_words)) {
    words <- par_words[[p]]
    # Headings take their words from the paragraph they introduce, so the total stays word_count.
    if (length(heading_levels) && p > 1 && length(words) > 1) {
      lv <- heading_levels[(p - 2) %% length(heading_levels) + 1]
      k <- min(sample(1:3, 1), length(words) - 1)
      items[[length(items) + 1]] <- list(words = words[seq_len(k)], size = sizes[lv],
                                         family = fam(3), face = "bold")
      words <- words[-seq_len(k)]
    }
    items[[length(items) + 1]] <- list(words = words, size = body, family = main$family, face = main$face)
  }

  # Regions (pixels, bottom-left origin): title, image(s) and text.
  share <- if (d$artefact_type == "data_chart") max(d$image_text_ratio, 0.55) else d$image_text_ratio
  share <- clamp(share, 0.05, 0.9)
  if (d$layout == "asymmetric") share <- clamp(share, 0.2, 0.7)
  title_w <- switch(d$layout, asymmetric = cw * (1 - share) - gap,
                    freeform = cw * stats::runif(1, 0.6, 0.9), cw)
  title_item <- list(words = title, size = sizes[1], family = fam(min(2, length(families))),
                     face = main$title_face)
  title_lines <- length(wrap_words(title, floor(title_w / (sizes[1] * char_width(title_item$family, title_item$face)))))
  th <- title_lines * sizes[1] * d$line_spacing + gap
  portrait <- H >= W
  R <- c(x0, y0, cw, ch - th - gap)
  just <- if (d$layout == "centred") "centre" else "left"
  title_rect <- c(x0, y0 + ch - th, title_w, th)
  if (d$layout %in% c("grid", "centred")) {
    if (portrait || d$layout == "centred") {
      img <- list(c(R[1], R[2] + R[4] * (1 - share), R[3], R[4] * share))
      txt <- list(c(R[1], R[2], R[3], R[4] * (1 - share) - gap))
    } else {
      img <- list(c(R[1], R[2], R[3] * share, R[4]))
      txt <- list(c(R[1] + R[3] * share + gap, R[2], R[3] * (1 - share) - gap, R[4]))
    }
  } else if (d$layout == "modular") {
    tw <- (R[3] - gap) / 2; tht <- (R[4] - gap) / 2
    tiles <- list(c(R[1], R[2] + tht + gap, tw, tht), c(R[1] + tw + gap, R[2] + tht + gap, tw, tht),
                  c(R[1], R[2], tw, tht), c(R[1] + tw + gap, R[2], tw, tht))
    n_img <- clamp(round(share * 4), 1, 3)
    order <- sample(4)
    img <- tiles[order[seq_len(n_img)]]
    txt <- tiles[sort(order[-seq_len(n_img)])]
  } else if (d$layout == "asymmetric") {
    left_w <- cw * (1 - share) - gap
    img <- list(c(x0 + left_w + gap, 0, W - (x0 + left_w + gap), H))
    title_rect <- c(x0, y0 + ch - th, left_w, th)
    txt <- list(c(x0, y0, left_w, ch - th - gap))
  } else {
    title_rect <- c(x0 + stats::runif(1) * (cw - title_w), y0 + ch - th, title_w, th)
    iw <- cw * sqrt(share); ih <- R[4] * sqrt(share)
    img <- list(c(x0 + stats::runif(1) * (cw - iw), R[2] + stats::runif(1) * (R[4] - ih), iw, ih))
    tw <- cw * stats::runif(1, 0.5, 0.8)
    txt <- list(c(x0 + stats::runif(1) * (cw - tw), R[2], tw, R[4] * stats::runif(1, 0.5, 0.9)))
  }
  img <- lapply(img, function(r) { r[1] <- r[1] + stats::rnorm(1, 0, jitter); r })

  grDevices::png(path, width = W, height = H, res = 72, type = "cairo")
  on.exit(grDevices::dev.off())
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(xscale = c(0, W), yscale = c(0, H)))
  rect_shape(0, 0, W, H, fill = cp$bg)

  for (k in seq_along(img)) {
    r <- img[[k]]
    if (r[3] <= 2 || r[4] <= 2) next
    if (k == 1 && d$artefact_type == "data_chart") {
      draw_chart(r, d$chart_type, palette, cp$fg, cp$bg, d$data_ink_ratio, body)
    } else if (k == 1 && d$artefact_type == "infographic") {
      draw_infographic(r, palette, cp$fg, d$data_ink_ratio, body, d$human_face)
    } else {
      draw_composition(r, palette, d$focal_point, d$human_face && k == 1)
    }
  }
  if (d$focal_point && length(palette) > 1) {
    rect_shape(title_rect[1], title_rect[2] - gap * 0.4, min(title_rect[3], cw * 0.25), max(2, body * 0.3),
               fill = palette[length(palette)])
  }
  drawn <- draw_text(list(title_item), title_rect, just, cp$fg, d$line_spacing, jitter)$drawn
  for (r in txt) {
    if (!length(items) || r[3] <= body * 3 || r[4] <= body) next
    res <- draw_text(items, r, just, cp$fg, d$line_spacing, jitter)
    items <- res$items
    drawn <- drawn + res$drawn
  }
  list(size = size, bg = cp$bg, fg = cp$fg, palette = palette, words_drawn = as.integer(drawn))
}
