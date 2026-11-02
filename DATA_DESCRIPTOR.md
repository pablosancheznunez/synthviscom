# Data descriptor: SynthVisCom 0.1.0

**Synthetic Dataset for Visual Communication Education and Research**

Author: Pablo Sánchez-Núñez ([ORCID 0000-0001-7845-9506](https://orcid.org/0000-0001-7845-9506)) · Data licence: [CC BY 4.0](LICENSE-DATA.md) · Code licence: [MIT](LICENSE)

## SYNTHETIC DATA

Every value in this dataset was produced by a computer simulation. No person
took part, no design was measured and no result is an empirical finding. Use
the data for teaching, for demonstrating methods and for testing analysis
code. Do not cite them as evidence about how people perceive design.

- **Synthetic.** Every value comes from random number generators in R.
- **Plausible, not calibrated.** Effect sizes and prevalences were chosen to
  be pedagogically clear and broadly in line with design guidance (for
  example WCAG contrast thresholds). They are not estimates from the
  literature.
- **Reproducible.** `Rscript code/build.R` rebuilds every file byte for byte
  from fixed seeds; `Rscript code/check.R` verifies this against `MD5SUMS`
  and the image checksums.

## Files

| File | Rows | Columns | Content |
|---|---|---|---|
| `data/synthetic_designs.csv` | 2,000 | 24 | Fictitious visual designs and their attributes |
| `data/synthetic_participants.csv` | 1,000 | 7 | Fictitious participants |
| `data/synthetic_responses.csv` | 20,000 | 12 | Simulated responses (20 designs per participant) |
| `metadata/codebook.csv` | 43 | 7 | Data dictionary: table, variable, type, unit, allowed values, role and description |
| `metadata/true_effects.csv` | 71 | 5 | Every effect used to simulate the responses |
| `images/D0001.png` … `D2000.png` | 2,000 files | | One synthetic image per design, drawn from its variables |
| `metadata/images.csv` | 2,000 | 10 | Image manifest: file, size, colours drawn, rendered contrast, palette, words that fitted, MD5 |
| `MD5SUMS` | | | Checksums of the CSV files (image checksums are in `metadata/images.csv`) |
| `code/generator.R` | | | The simulation model (base R) |
| `code/render.R` | | | The image renderer (base R, grid and the cairo PNG device) |
| `code/build.R`, `code/check.R` | | | Rebuild and validate the files |

Format: comma-separated, UTF-8, LF line endings, header row, text in double
quotes, missing values as empty cells, logical values as `TRUE`/`FALSE`.

## Structure

```
synthetic_participants (1,000)      synthetic_designs (2,000)
            \                              /
             \--- synthetic_responses (20,000) ---/
         each participant sees 20 different designs in random order
```

`synthetic_responses.csv` links to the other tables through
`participant_id` and `design_id`. Designs are drawn with seed 2026,
participants with 2027 and responses with 2028, so changing one table's size
in `vc_generate()` leaves the others unchanged. Missing values occur only by
design: `chart_type` is empty for anything that is not a data chart, and
`data_ink_ratio` for anything that is not a data chart or an infographic.

## Designs

The artefact type is drawn first (posters 20%, infographics 20%, data charts
20%, social media images 25%, slides 15%) and shapes several other
attributes: typical body text size (10 pt for charts and infographics up to
24 pt for slides), the median word count (15 words for social media images
up to 180 for infographics) and the share of imagery.

Contrast ratios follow a log-normal distribution centred on 6:1 and clipped
to 1.2-21, so about a quarter of designs fail WCAG 2 AA.
`wcag_aa_contrast` applies the 4.5:1 threshold, or 3:1 for text of 18 pt or
more.

`visual_complexity` is a derived index:

$$
\text{complexity} = 100\,\text{logit}^{-1}\big(0.35(\text{colours}-4) + 0.8\log(\text{words}/50) - 0.04(\text{whitespace}-38) + 0.4(\text{typefaces}-2) + 0.25(\text{levels}-3)\big)
$$

## Images

Each design has a PNG image, `images/<design_id>.png`, drawn by
`code/render.R` from that design's row, so image and table always agree.
The images are abstract compositions, not real designs: text is meaningless
pseudo-text, imagery is made of geometric shapes, and faces are schematic
illustrations, never photographs of people.

| Variable | How it is drawn |
|---|---|
| `artefact_type` | Canvas proportions (longest side 800 px): poster 566×800, infographic 450×800, data chart 800×600, social media image 800×800, slide 800×450; and the kind of content (chart, infographic with a big number and icon row, or an abstract composition) |
| `n_colours`, `colour_harmony`, `mean_saturation` | Palette in HCL space: hues from the harmony scheme, chroma from saturation |
| `colour_scheme`, `contrast_ratio` | Background tinted with the palette hue (light or dark); body text is a neutral grey whose WCAG contrast with the background is solved to match `contrast_ratio` (the drawn value is `rendered_contrast` in the manifest, within 3%) |
| `n_typefaces`, `typeface_class` | Font families (sans, serif, mono) and faces; display titles are upper case, script designs are italic |
| `body_text_pt`, `line_spacing` | Body text size (1 pt = 1 px) and leading |
| `hierarchy_levels` | Number of distinct text sizes, in a 1.45 ratio: title, subtitle, headings and body |
| `layout`, `alignment_consistency`, `whitespace_pct` | Placement of title, imagery and text (grid, modular 2×2 tiles, asymmetric with bleed, centred, freeform); random horizontal offsets that grow as alignment falls; margins that leave the stated share empty |
| `focal_point` | One dominant shape (or a large face) and an accent rule under the title, versus many similar small shapes |
| `image_text_ratio` | Share of the content area given to imagery (at least 55% for data charts) |
| `word_count` | Words of pseudo-text; when they do not fit, the rest is cut, and `words_drawn` records how many were drawn |
| `human_face` | A schematic face with varied skin and hair colours |
| `chart_type`, `data_ink_ratio` | The chart drawn (bar, line, pie, scatter, map, table); a low data-ink ratio adds panel fills, heavy gridlines, borders and drop shadows |

Images use their own seeds (3000 + row number), so the tabular data do not
depend on them. Rebuilding on the same system gives byte-identical PNGs;
on other operating systems the system fonts, and so the exact pixels, may
differ slightly, while colours, sizes and layout stay the same.

The simulated responses depend on the variables, not on the pixels: the
images illustrate the designs, they did not cause the responses.

## Participants

Age band, design expertise and device are drawn independently. Visual
literacy is normal with mean 45 (no training), 55 (students) or 65
(professionals) and SD 14, clipped to 0-100. Colour vision deficiency
affects about 4.5% of participants (deutan 3%, protan 1.2%, tritan 0.3%);
low vision affects 2%, or 8% of those aged 55 and over. These are teaching
values, not population estimates.

## Effective contrast

Each response first computes the contrast the participant actually
experiences:

$$
c_{\text{eff}} = 1 + (c - 1)\, m_{\text{cvd}}\, m_{\text{lv}}
$$

where $m_{\text{cvd}} = 0.55$ for red-green deficiency (deutan, protan)
viewing complementary or triadic palettes, or tritan deficiency viewing
triadic palettes, and $m_{\text{lv}} = 0.60$ for low vision; otherwise both
are 1. The model then uses $\ell = \log(c_{\text{eff}} / 4.5)$, split into a
part below the AA threshold, $\min(\ell, 0)$, and a part above it,
$\max(\ell, 0)$. Contrast therefore matters a lot below 4.5:1 and little
above it, and matters more for people with colour vision deficiency or low
vision. Effective contrast is not stored in the data: computing it is one of
the exercises.

## Outcome models

All outcomes include random intercepts for participants, and comprehension
and aesthetic appeal also for designs. Continuous predictors are centred
(complexity at 50, visual literacy at 50, saturation at 0.5, image/text
ratio at 0.5, word count on a log scale at 50 words).

| Outcome | Model |
|---|---|
| `comprehension_score` | Binomial(5, p), logit(p) linear in contrast, hierarchy, word count, complexity, focal point, visual literacy, data-ink ratio, pie charts and small text on mobile |
| `time_to_first_fixation_ms` | Log-normal: contrast, faces, focal point, saturation, complexity |
| `dwell_time_s` | Log-normal: word count, complexity, mobile, the design's latent aesthetic appeal |
| `aesthetic_rating` | Latent normal cut into 1-7: palette harmony, number of colours, whitespace, alignment (stronger for professionals), typefaces, complexity |
| `preference_rating` | Latent normal cut into 1-7: aesthetic appeal, faces, saturation, imagery |
| `cognitive_load` | Normal, clipped to 0-100: complexity, low contrast, word count, visual literacy |
| `recall_24h` | Bernoulli: faces, imagery, focal point, comprehension, dwell time, complexity |
| `engaged` | Bernoulli: preference rating, social media images, faces, mobile |

The 1-7 ratings cut the latent variable at -2.0, -1.2, -0.45, 0.3, 1.05
and 1.85. Because recall depends on comprehension and dwell time, and
engagement on preference, the data contain mediated paths: a design feature
can affect recall directly and through comprehension.

Every coefficient, with its scale and meaning, is in
`metadata/true_effects.csv` (and `vc_true_effects()` in
`code/generator.R`, which is the single source the simulation reads).

## What the data cannot do

- They cannot tell you how real audiences respond to design. Any "finding"
  from them is a property of the model above.
- The images are schematic: no photography, illustration style, real
  typography or meaningful text. The model has no culture, language, context
  of use or purpose of the message, all of which matter in real visual
  communication.
- Effects are additive on their scales apart from the documented
  interactions (contrast with colour vision and low vision, alignment with
  professional expertise, text size with mobile viewing). Real data are
  messier.
- There are no data entry errors and no missing values beyond the
  structural ones. Add them yourself if you want to teach data cleaning.

## Suggested uses

- Teaching descriptive statistics, data visualisation and regression with
  visual communication examples (see `examples/`).
- Accessibility auditing exercises (WCAG contrast, colour vision deficiency).
- Design critique with images whose properties are known exactly, and
  image-analysis or computer-vision exercises (for example, estimating
  contrast, colourfulness or text density from the pixels and checking
  against the table).
- Checking whether a modelling approach recovers known effects.
- Simulation-based power analysis when planning a real design study, by
  calling `vc_generate()` with other sizes and seeds.

Synthetic data let students practise the whole analysis cycle with no
privacy risk and a known right answer. They complement, and never replace,
studies with real people.

## Citation

Sánchez-Núñez, P. (2026). *Synthetic Dataset for Visual Communication
Education and Research* (SynthVisCom, Version 0.1.0) [Data set].
https://github.com/pablosancheznunez/synthviscom
