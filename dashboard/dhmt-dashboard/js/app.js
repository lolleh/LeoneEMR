/* DHMT KPI Dashboard — scorecard render logic
 * Mirrors KPI Dashboard spreadsheet structure. */

const CATEGORY_COLORS = {
  "Impact & Health Outcomes": "#d64541",
  "RMNCAH & Service Delivery": "#0e6f4e",
  "Health System & Readiness": "#3b82c4",
  "Surveillance & Data": "#e8a13c"
};

function districtFilter() {
  return document.getElementById("districtSelect").value;
}

function programFilter() {
  const el = document.querySelector(".program-tab.active");
  return el ? el.dataset.program : "all";
}

function actualFor(kpi, d) {
  const map = DISTRICT_ACTUALS[kpi.id];
  if (map && map[d]) return map[d];
  if (d !== "all" && map && map.karena) return map.karena;
  return kpi.actual;
}

function monthlyFor(kpi) {
  if (kpi.monthly) return kpi.monthly;
  const steps = 12, out = [];
  const base = kpi.target * 0.6;
  for (let i = 0; i < steps; i++) {
    const t = i / (steps - 1);
    out.push(Math.round(base + (kpi.actual - base) * t));
  }
  return out;
}

function districtMonthly(kpi) {
  const d = districtFilter();
  const base = monthlyFor(kpi);
  if (d === "all") return base;
  const actual = actualFor(kpi, d);
  const ratio = actual / kpi.actual;
  return base.map(v => {
    const scaled = v * ratio;
    return Number.isInteger(Number(kpi.actual)) ? Math.round(scaled) : Math.round(scaled * 10) / 10;
  });
}

function statusFor(kpi, actual) {
  if (kpi.direction === "lower") {
    if (actual <= kpi.target) return { cls: "on-track", label: "On Track" };
    if (actual <= kpi.target * 1.15) return { cls: "at-risk", label: "At Risk" };
    return { cls: "off-track", label: "Off Track" };
  }
  const pct = (actual / kpi.target) * 100;
  if (pct >= 90) return { cls: "on-track", label: "On Track" };
  if (pct >= 75) return { cls: "at-risk", label: "At Risk" };
  return { cls: "off-track", label: "Off Track" };
}

function fmt(v, kpi) {
  if (typeof v === "number") return v.toLocaleString(undefined, { maximumFractionDigits: 1 });
  return v;
}

function cellSuffix(kpi) {
  return kpi.unit.includes("%") ? "%" : "";
}

function renderTabs() {
  const bar = document.getElementById("programTabs");
  const cats = ["all", ...new Set(KPI_DEFS.map(k => k.category))];
  bar.innerHTML = "";
  cats.forEach(cat => {
    const pill = document.createElement("button");
    pill.className = "program-tab" + (cat === "all" ? " active" : "");
    pill.dataset.program = cat;
    pill.textContent = cat === "all" ? "All Programs" : cat;
    if (cat !== "all") pill.style.backgroundColor = CATEGORY_COLORS[cat] + "22";
    pill.addEventListener("click", () => {
      document.querySelectorAll(".program-tab").forEach(p => p.classList.remove("active"));
      pill.classList.add("active");
      renderScorecard();
    });
    bar.appendChild(pill);
  });
}

function renderLegend() {
  const leg = document.getElementById("legend");
  leg.innerHTML = "";
  LEGEND.forEach(item => {
    const dot = document.createElement("span");
    dot.className = "legend-item";
    dot.innerHTML = `<i style="background:${item.color}"></i>${item.label}`;
    leg.appendChild(dot);
  });
}

function sparkline(values, width, height) {
  const min = Math.min(...values), max = Math.max(...values);
  const range = max - min || 1;
  const pts = values.map((v, i) => {
    const x = (i / (values.length - 1)) * (width - 4) + 2;
    const y = height - 3 - ((v - min) / range) * (height - 6);
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  });
  return `<svg class="spark" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    <polyline fill="none" stroke="#0e6f4e" stroke-width="1.5" points="${pts.join(" ")}"/>
  </svg>`;
}

function renderScorecard() {
  const tbody = document.querySelector("#scorecard tbody");
  tbody.innerHTML = "";
  const prog = programFilter();
  const d = districtFilter();

  const kpis = KPI_DEFS.filter(k => prog === "all" || k.category === prog);

  kpis.forEach(kpi => {
    const actual = actualFor(kpi, d);
    const status = statusFor(kpi, actual);
    const months = districtMonthly(kpi);
    const monthCells = months.map(v =>
      `<td class="month-cell" title="${v}${cellSuffix(kpi)}">${fmt(v, kpi)}${cellSuffix(kpi)}</td>`
    ).join("");

    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td class="program-cell"><span style="display:inline-block;width:10px;height:10px;border-radius:2px;background:${CATEGORY_COLORS[kpi.category]};margin-right:8px"></span>${kpi.category}</td>
      <td class="indicator-cell">${kpi.label}</td>
      <td>${fmt(kpi.baseline, kpi)}${cellSuffix(kpi)}</td>
      <td>${fmt(kpi.target, kpi)}${cellSuffix(kpi)}</td>
      <td class="to-date"><span class="badge to-date-badge ${status.cls}">${fmt(actual, kpi)}${cellSuffix(kpi)}</span></td>
      ${monthCells}
      <td class="trend-cell">${sparkline(months, 90, 34)}</td>
      <td class="source-cell">${kpi.source}</td>
      <td class="comment-cell">${kpi.comments}</td>
    `;
    tbody.appendChild(tr);
  });

  document.getElementById("kpiCount").textContent = `Showing ${kpis.length} indicators`;
}

function exportCsv() {
  const d = districtFilter();
  const prog = programFilter();
  const kpis = KPI_DEFS.filter(k => prog === "all" || k.category === prog);

  const header = ["Program", "Indicator", "Baseline", "Target", "To Date",
    ...MONTHS, "Source", "Comments", "Status"];
  const rows = kpis.map(kpi => {
    const actual = actualFor(kpi, d);
    return [
      `"${kpi.category}"`,
      `"${kpi.label}"`,
      kpi.baseline,
      kpi.target,
      actual,
      ...districtMonthly(kpi),
      `"${kpi.source}"`,
      `"${kpi.comments}"`,
      `"${statusFor(kpi, actual).label}"`
    ].join(",");
  });

  const csv = [header.join(","), ...rows].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  const date = new Date().toISOString().slice(0, 10);
  a.href = url;
  a.download = `dhmt-kpi-${d}-${date}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/* =============== Tab navigation =============== */
document.querySelectorAll(".tab-btn").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    document.getElementById("scorecardSec").hidden = btn.dataset.sec !== "scorecardSec";
    document.getElementById("detailSec").hidden = btn.dataset.sec !== "detailSec";
  });
});

/* =============== Detail Reporting dashboard =============== */
function selectedFacility() {
  return document.getElementById("facilitySelect").value;
}

function renderFacilitySelect() {
  const sel = document.getElementById("facilitySelect");
  const district = document.getElementById("districtDetailSelect").value;
  const list = district === "all" ? FACILITIES : FACILITIES.filter(f => f.district === district);
  const current = sel.value;
  sel.innerHTML = "";
  list.forEach(f => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = `${f.name} (${f.district === "falaba" ? "Falaba" : "Karena"})`;
    sel.appendChild(opt);
  });
  if (!current || !list.some(f => f.name === current)) {
    sel.value = list[0] ? list[0].name : "";
  } else {
    sel.value = current;
  }
  renderChips();
  renderDetailMatrix();
}

function renderChips() {
  const chips = document.getElementById("chips");
  chips.innerHTML = "";
  const isSel = selectedFacility() === FORM_FACILITY;
  const reported = FORM_MONTHS.filter(m => isSel && m.c && m.c.some(v => v !== null));
  const pending = isSel ? FORM_MONTHS.length - reported.length : FORM_MONTHS.length;
  const colSum = i => reported.reduce((s, m) => s + (m.c[i] || 0), 0);
  const anc1stContact = isSel ? colSum(0) : 0;
  const totalDeliveries = isSel ? colSum(12) : 0;
  const maternalDeaths = isSel ? colSum(21) : 0;
  const cellsRecorded = isSel ? reported.reduce((s, m) => s + m.c.filter(v => v !== null).length, 0) : 0;
  const chipsData = [
    { label: "Months Reported", value: `${reported.length} / ${FORM_MONTHS.length}`, cls: "chip-primary" },
    { label: "Total Deliveries", value: totalDeliveries.toLocaleString(), cls: "chip-ok" },
    { label: "ANC 1st Contact", value: anc1stContact.toLocaleString(), cls: "chip-ok" },
    { label: "Maternal Deaths", value: maternalDeaths.toLocaleString(), cls: "chip-neutral" },
    { label: "Cells Recorded", value: cellsRecorded.toLocaleString(), cls: "chip-neutral" }
  ];
  chipsData.forEach(c => {
    const div = document.createElement("div");
    div.className = `chip ${c.cls}`;
    div.innerHTML = `<span class="chip-label">${c.label}</span><span class="chip-value">${c.value}</span>`;
    chips.appendChild(div);
  });
}

function renderDetailMatrix() {
  const table = document.getElementById("detailMatrix");
  const thead = table.querySelector("thead");
  const tbody = table.querySelector("tbody");
  const isSel = selectedFacility() === FORM_FACILITY;

  const bands = [];
  FORM_GROUPS.forEach((g, gi) => {
    g.subs.forEach((s, si) => {
      s.cols.forEach(() => bands.push({ gi, si }));
    });
  });
  const totalCols = bands.length;

  thead.innerHTML = "";
  const groupRow = document.createElement("tr");
  const blankTh = document.createElement("th");
  blankTh.className = "month-label-th";
  blankTh.textContent = "Months";
  groupRow.appendChild(blankTh);
  FORM_GROUPS.forEach((g, gi) => {
    const th = document.createElement("th");
    th.colSpan = g.subs.reduce((s, x) => s + x.cols.length, 0);
    th.className = `group-head g${gi}`;
    th.textContent = g.name;
    groupRow.appendChild(th);
  });
  thead.appendChild(groupRow);

  const subRow = document.createElement("tr");
  subRow.appendChild(document.createElement("th"));
  FORM_GROUPS.forEach((g, gi) => {
    if (g.subs.length === 1 && g.subs[0].name === "") {
      const th = document.createElement("th");
      th.colSpan = g.subs[0].cols.length;
      th.className = `sub-head blank g${gi}`;
      subRow.appendChild(th);
    } else {
      g.subs.forEach((s, si) => {
        const th = document.createElement("th");
        th.colSpan = s.cols.length;
        th.className = `sub-head g${gi}`;
        th.textContent = s.name;
        subRow.appendChild(th);
      });
    }
  });
  thead.appendChild(subRow);

  const labelRow = document.createElement("tr");
  const labelBlank = document.createElement("th");
  labelBlank.className = "month-label-th";
  labelRow.appendChild(labelBlank);
  FORM_GROUPS.forEach((g, gi) => {
    g.subs.forEach(s => {
      s.cols.forEach(c => {
        const th = document.createElement("th");
        th.className = `col-head g${gi}` + (g.wrap ? " tight" : "");
        th.textContent = c;
        labelRow.appendChild(th);
      });
    });
  });
  thead.appendChild(labelRow);

  tbody.innerHTML = "";
  let filled = 0;
  FORM_MONTHS.forEach(mo => {
    const tr = document.createElement("tr");
    const th = document.createElement("th");
    th.className = "month-label";
    th.textContent = mo.m;
    tr.appendChild(th);

    const cells = isSel ? (mo.c || []) : [];
    const hasData = isSel && cells.some(v => v !== null);
    if (hasData) filled++;
    for (let i = 0; i < totalCols; i++) {
      const td = document.createElement("td");
      const { gi, si } = bands[i];
      td.className = `cell cg${gi} sub${si}` + (hasData ? "" : " pending");
      if (i === 0 || bands[i - 1].gi !== gi) td.classList.add("group-start");
      const v = cells[i];
      if (v === null || v === undefined) {
        td.textContent = "·";
        td.classList.add("empty");
      } else {
        td.textContent = String(v);
        td.classList.add("num");
      }
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  });

  const totalRow = document.createElement("tr");
  totalRow.className = "total-row";
  const totalTh = document.createElement("th");
  totalTh.className = "month-label";
  totalTh.textContent = "Total";
  totalRow.appendChild(totalTh);
  for (let i = 0; i < totalCols; i++) {
    const { gi, si } = bands[i];
    const sum = isSel ? FORM_MONTHS.reduce((s, mo) => s + ((mo.c && mo.c[i]) || 0), 0) : 0;
    const td = document.createElement("td");
    td.className = `cell cg${gi} sub${si} num total-cell`;
    if (i === 0 || bands[i - 1].gi !== gi) td.classList.add("group-start");
    td.textContent = sum === 0 ? "·" : String(sum);
    totalRow.appendChild(td);
  }
  tbody.appendChild(totalRow);

  document.getElementById("detailCount").textContent = isSel
    ? `${filled} / ${FORM_MONTHS.length} months reported`
    : "No data for this facility";
}

function exportDetailCsv() {
  const cols = FORM_GROUPS.reduce((arr, g) => {
    g.subs.forEach(s => {
      s.cols.forEach(c => {
        arr.push(s.name ? `${g.name} — ${s.name} — ${c}` : `${g.name} — ${c}`);
      });
    });
    return arr;
  }, []);
  const idx = i => cols[i];
  const rows = [["Month", ...cols].join(",")];
  FORM_MONTHS.forEach(mo => {
    const vals = mo.c ? mo.c.map(v => (v === null ? "" : String(v))) : cols.map(() => "");
    rows.push([mo.m, ...vals].join(","));
  });
  const csv = rows.join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `dhmt-monthly-form-${new Date().toISOString().slice(0, 10)}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

document.getElementById("exportBtn").addEventListener("click", exportCsv);
document.getElementById("districtSelect").addEventListener("change", renderScorecard);
document.getElementById("districtDetailSelect").addEventListener("change", renderFacilitySelect);
document.getElementById("facilitySelect").addEventListener("change", () => { renderChips(); renderDetailMatrix(); });
document.getElementById("exportDetailBtn").addEventListener("click", exportDetailCsv);

renderLegend();
renderTabs();
renderScorecard();
renderFacilitySelect();