// SynthVisCom design explorer: browse the 2,000 synthetic designs and their images.
// Reads the published CSV files directly; no libraries. Code licence: MIT.
(function () {
  "use strict";

  var root = document.getElementById("explorer");
  if (!root) return;
  var base = root.getAttribute("data-base") || "";
  var lang = document.documentElement.lang === "es" ? "es" : "en";

  var T = {
    en: {
      loading: "Loading the synthetic designs…",
      failed: "The data could not be loaded. You can still download the CSV files below.",
      count: function (n, total) { return "Showing " + n + " of " + total.toLocaleString("en") + " matching designs"; },
      none: "No design matches these filters.",
      more: "Show more",
      all: "All",
      pass: "Meets WCAG AA", fail: "Fails WCAG AA",
      yes: "Yes", no: "No",
      contrast: "contrast",
      close: "Close",
      variables: "Design variables",
      drawn: "As drawn",
      responses: "Mean simulated responses",
      responsesNote: function (n) { return "Synthetic: " + n + " simulated participants saw this design."; },
      loadingResponses: "Loading responses…",
      sortId: "Identifier", sortLow: "Lowest contrast first", sortHigh: "Highest contrast first",
      sortComplex: "Most complex first", sortSimple: "Least complex first",
      face: "with a schematic face",
      layoutWord: "layout",
      alt: function (d) {
        return types[d.artefact_type] + " " + d.design_id + ", " + d.layout + " " + this.layoutWord +
          ", text contrast " + d.contrast_ratio + ":1" + (d.human_face === "TRUE" ? ", " + this.face : "") +
          ". Synthetic image with meaningless pseudo-text.";
      },
      labels: {
        background_colour: "Background", text_colour: "Text colour", rendered_contrast: "Rendered contrast",
        palette: "Palette", words_drawn: "Words drawn", size: "Size (px)",
        time_to_first_fixation_ms: "Time to first fixation (ms)", dwell_time_s: "Dwell time (s)",
        comprehension_score: "Comprehension (0-5)", aesthetic_rating: "Aesthetic rating (1-7)",
        preference_rating: "Preference (1-7)", cognitive_load: "Cognitive load (0-100)",
        recall_24h: "Recall after 24 h", engaged: "Engaged (like, share, save)"
      }
    },
    es: {
      loading: "Cargando los diseños sintéticos…",
      failed: "No se pudieron cargar los datos. Puedes descargar los CSV más abajo.",
      count: function (n, total) { return "Se muestran " + n + " de " + total.toLocaleString("es") + " diseños"; },
      none: "Ningún diseño cumple estos filtros.",
      more: "Mostrar más",
      all: "Todos",
      pass: "Cumple WCAG AA", fail: "No cumple WCAG AA",
      yes: "Sí", no: "No",
      contrast: "contraste",
      close: "Cerrar",
      variables: "Variables del diseño",
      drawn: "Tal como se dibujó",
      responses: "Respuestas simuladas (media)",
      responsesNote: function (n) { return "Sintéticas: " + n + " participantes simulados vieron este diseño."; },
      loadingResponses: "Cargando respuestas…",
      sortId: "Identificador", sortLow: "Menor contraste primero", sortHigh: "Mayor contraste primero",
      sortComplex: "Más complejos primero", sortSimple: "Menos complejos primero",
      face: "con un rostro esquemático",
      layoutWord: "maquetación",
      alt: function (d) {
        return types[d.artefact_type] + " " + d.design_id + ", maquetación " + d.layout +
          ", contraste del texto " + d.contrast_ratio + ":1" + (d.human_face === "TRUE" ? ", " + this.face : "") +
          ". Imagen sintética con pseudotexto sin significado.";
      },
      labels: {
        background_colour: "Fondo", text_colour: "Color del texto", rendered_contrast: "Contraste dibujado",
        palette: "Paleta", words_drawn: "Palabras dibujadas", size: "Tamaño (px)",
        time_to_first_fixation_ms: "Tiempo hasta la primera fijación (ms)", dwell_time_s: "Tiempo de visualización (s)",
        comprehension_score: "Comprensión (0-5)", aesthetic_rating: "Valoración estética (1-7)",
        preference_rating: "Preferencia (1-7)", cognitive_load: "Carga cognitiva (0-100)",
        recall_24h: "Recuerdo a las 24 h", engaged: "Interacción (like, compartir, guardar)"
      }
    }
  }[lang];

  var types = lang === "es"
    ? { poster: "Cartel", infographic: "Infografía", data_chart: "Gráfico de datos", social_media_image: "Imagen para redes", slide: "Diapositiva" }
    : { poster: "Poster", infographic: "Infographic", data_chart: "Data chart", social_media_image: "Social media image", slide: "Slide" };

  var PAGE = 48;
  var designs = [], images = {}, responses = null, shown = PAGE;
  var el = {
    type: root.querySelector("[name=type]"), wcag: root.querySelector("[name=wcag]"),
    layout: root.querySelector("[name=layout]"), face: root.querySelector("[name=face]"),
    sort: root.querySelector("[name=sort]"), count: root.querySelector(".count"),
    grid: root.querySelector(".grid"), more: root.querySelector(".more"),
    dialog: root.querySelector("dialog")
  };

  // Minimal RFC 4180 CSV parser (quoted fields, doubled quotes).
  function parseCSV(text) {
    var rows = [], row = [], field = "", i = 0, q = false, c;
    while (i < text.length) {
      c = text[i];
      if (q) {
        if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else q = false; }
        else field += c;
      } else if (c === '"') q = true;
      else if (c === ",") { row.push(field); field = ""; }
      else if (c === "\n" || c === "\r") {
        if (c === "\r" && text[i + 1] === "\n") i++;
        row.push(field); rows.push(row); row = []; field = "";
      } else field += c;
      i++;
    }
    if (field !== "" || row.length) { row.push(field); rows.push(row); }
    var head = rows.shift();
    return rows.filter(function (r) { return r.length === head.length; }).map(function (r) {
      var o = {};
      head.forEach(function (h, k) { o[h] = r[k]; });
      return o;
    });
  }

  function get(path) {
    return fetch(base + path).then(function (r) {
      if (!r.ok) throw new Error(path + " " + r.status);
      return r.text();
    }).then(parseCSV);
  }

  function option(select, value, label) {
    var o = document.createElement("option");
    o.value = value; o.textContent = label;
    select.appendChild(o);
  }

  function fillFilters() {
    option(el.type, "", T.all);
    Object.keys(types).forEach(function (k) { option(el.type, k, types[k]); });
    option(el.wcag, "", T.all); option(el.wcag, "TRUE", T.pass); option(el.wcag, "FALSE", T.fail);
    option(el.layout, "", T.all);
    ["grid", "modular", "asymmetric", "centred", "freeform"].forEach(function (k) { option(el.layout, k, k); });
    option(el.face, "", T.all); option(el.face, "TRUE", T.yes); option(el.face, "FALSE", T.no);
    [["id", T.sortId], ["low", T.sortLow], ["high", T.sortHigh], ["complex", T.sortComplex], ["simple", T.sortSimple]]
      .forEach(function (s) { option(el.sort, s[0], s[1]); });
  }

  function filtered() {
    var out = designs.filter(function (d) {
      return (!el.type.value || d.artefact_type === el.type.value) &&
        (!el.wcag.value || d.wcag_aa_contrast === el.wcag.value) &&
        (!el.layout.value || d.layout === el.layout.value) &&
        (!el.face.value || d.human_face === el.face.value);
    });
    var key = el.sort.value, num = function (d, f) { return parseFloat(d[f]); };
    if (key === "low") out.sort(function (a, b) { return num(a, "contrast_ratio") - num(b, "contrast_ratio"); });
    if (key === "high") out.sort(function (a, b) { return num(b, "contrast_ratio") - num(a, "contrast_ratio"); });
    if (key === "complex") out.sort(function (a, b) { return num(b, "visual_complexity") - num(a, "visual_complexity"); });
    if (key === "simple") out.sort(function (a, b) { return num(a, "visual_complexity") - num(b, "visual_complexity"); });
    return out;
  }

  function render() {
    var list = filtered();
    el.grid.textContent = "";
    el.count.textContent = list.length ? T.count(Math.min(shown, list.length), list.length) : T.none;
    list.slice(0, shown).forEach(function (d) {
      var b = document.createElement("button");
      b.className = "tile"; b.type = "button";
      b.setAttribute("aria-label", T.alt(d));
      var th = document.createElement("span"); th.className = "thumb";
      var img = document.createElement("img");
      img.loading = "lazy"; img.decoding = "async"; img.alt = "";
      img.src = base + "images/" + d.design_id + ".png";
      th.appendChild(img);
      var meta = document.createElement("span"); meta.className = "meta";
      var pass = d.wcag_aa_contrast === "TRUE";
      meta.innerHTML = "<b>" + d.design_id + "</b> · " + types[d.artefact_type] + "<br>" + T.contrast + " " +
        d.contrast_ratio + ":1 " + (pass ? "" : '<span class="badge fail">AA ✕</span>');
      b.appendChild(th); b.appendChild(meta);
      b.addEventListener("click", function () { openDetail(d, b); });
      el.grid.appendChild(b);
    });
    el.more.hidden = list.length <= shown;
  }

  function row(table, label, value) {
    var tr = document.createElement("tr");
    var th = document.createElement("th"); th.scope = "row"; th.textContent = label;
    var td = document.createElement("td");
    if (value instanceof Node) td.appendChild(value); else td.textContent = value;
    tr.appendChild(th); tr.appendChild(td); table.appendChild(tr);
  }

  function swatches(hexes) {
    var wrap = document.createElement("span"); wrap.className = "swatches";
    hexes.forEach(function (h) {
      var s = document.createElement("span"); s.className = "swatch";
      s.style.background = h; s.title = h; s.setAttribute("role", "img"); s.setAttribute("aria-label", h);
      wrap.appendChild(s);
    });
    return wrap;
  }

  function fillResponses(d, box) {
    var mine = responses.filter(function (r) { return r.design_id === d.design_id; });
    box.textContent = "";
    var p = document.createElement("p"); p.className = "caption"; p.textContent = T.responsesNote(mine.length);
    var t = document.createElement("table");
    ["time_to_first_fixation_ms", "dwell_time_s", "comprehension_score", "aesthetic_rating",
      "preference_rating", "cognitive_load", "recall_24h", "engaged"].forEach(function (f) {
      var vals = mine.map(function (r) { return r[f] === "TRUE" ? 1 : r[f] === "FALSE" ? 0 : parseFloat(r[f]); });
      var mean = vals.reduce(function (a, b) { return a + b; }, 0) / (vals.length || 1);
      var shownValue = (f === "recall_24h" || f === "engaged") ? Math.round(mean * 100) + "%" :
        (mean >= 100 ? Math.round(mean).toString() : mean.toFixed(1));
      row(t, T.labels[f], vals.length ? shownValue : "–");
    });
    box.appendChild(t); box.appendChild(p);
  }

  function openDetail(d, opener) {
    var dlg = el.dialog, im = images[d.design_id] || {};
    dlg.textContent = "";
    var head = document.createElement("div"); head.className = "detail-head";
    var h = document.createElement("h3"); h.id = "detail-title";
    h.textContent = d.design_id + " · " + types[d.artefact_type];
    var close = document.createElement("button"); close.className = "close"; close.type = "button";
    close.textContent = T.close;
    close.addEventListener("click", function () { dlg.close(); });
    head.appendChild(h); head.appendChild(close);
    dlg.setAttribute("aria-labelledby", "detail-title");

    var body = document.createElement("div"); body.className = "detail";
    var left = document.createElement("div");
    var img = document.createElement("img");
    img.src = base + "images/" + d.design_id + ".png"; img.alt = T.alt(d);
    left.appendChild(img);
    var drawn = document.createElement("h4"); drawn.className = "subhead"; drawn.textContent = T.drawn;
    var dt = document.createElement("table");
    row(dt, T.labels.size, im.width_px + " × " + im.height_px);
    row(dt, T.labels.background_colour, swatches([im.background_colour]).appendChild(document.createTextNode(" " + im.background_colour)).parentNode);
    row(dt, T.labels.text_colour, swatches([im.text_colour]).appendChild(document.createTextNode(" " + im.text_colour)).parentNode);
    row(dt, T.labels.rendered_contrast, im.rendered_contrast + ":1");
    row(dt, T.labels.palette, swatches((im.palette || "").split(" ").filter(Boolean)));
    row(dt, T.labels.words_drawn, im.words_drawn + " / " + d.word_count);
    left.appendChild(drawn); left.appendChild(dt);

    var right = document.createElement("div");
    var vh = document.createElement("h4"); vh.className = "subhead"; vh.style.marginTop = "0"; vh.textContent = T.variables;
    var vt = document.createElement("table");
    Object.keys(d).forEach(function (k) {
      if (k === "design_id") return;
      row(vt, k, d[k] === "" ? "NA" : d[k]);
    });
    var rh = document.createElement("h4"); rh.className = "subhead"; rh.textContent = T.responses;
    var rbox = document.createElement("div"); rbox.textContent = T.loadingResponses;
    right.appendChild(vh); right.appendChild(vt); right.appendChild(rh); right.appendChild(rbox);
    body.appendChild(left); body.appendChild(right);
    dlg.appendChild(head); dlg.appendChild(body);
    dlg.onclose = function () { if (opener) opener.focus(); };
    dlg.showModal();
    close.focus();

    (responses ? Promise.resolve() : get("data/synthetic_responses.csv").then(function (r) { responses = r; }))
      .then(function () { fillResponses(d, rbox); })
      .catch(function () { rbox.textContent = T.failed; });
  }

  el.dialog.addEventListener("click", function (e) { if (e.target === el.dialog) el.dialog.close(); });
  [el.type, el.wcag, el.layout, el.face, el.sort].forEach(function (s) {
    s.addEventListener("change", function () { shown = PAGE; render(); });
  });
  el.more.textContent = T.more;
  el.more.addEventListener("click", function () { shown += PAGE; render(); });

  fillFilters();
  el.count.textContent = T.loading;
  Promise.all([get("data/synthetic_designs.csv"), get("metadata/images.csv")]).then(function (res) {
    designs = res[0];
    res[1].forEach(function (r) { images[r.design_id] = r; });
    render();
  }).catch(function () { el.count.textContent = T.failed; });
})();
