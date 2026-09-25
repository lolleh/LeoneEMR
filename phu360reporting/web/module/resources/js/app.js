(function () {
  "use strict";

  var API = window.location.pathname.split("/moduleResources/")[0] + "/moduleServlet/phu360reporting/reportApi";

  var PALETTE = ["#0e6f4e", "#e8a13c", "#d64541", "#5b7c99", "#7a4fa3", "#2f8f6b", "#c47bb2", "#4f8df7", "#9aa7b0", "#b5a642", "#3f7d20", "#8f5c38"];

  var state = { from: null, to: null, location: "", encounterType: "" };

  var charts = {};
  var dataCache = null;

  function $(id) { return document.getElementById(id); }

  function fmtDate(d) {
    var m = d.getMonth() + 1;
    var day = d.getDate();
    return d.getFullYear() + "-" + (m < 10 ? "0" + m : m) + "-" + (day < 10 ? "0" + day : day);
  }

  function defaultRange() {
    var to = new Date();
    var from = new Date();
    from.setDate(1);
    from.setMonth(from.getMonth() - 11);
    return { from: fmtDate(from), to: fmtDate(to) };
  }

  function fetchJson(url, onOk, onErr) {
    fetch(url, { credentials: "same-origin" })
      .then(function (r) { if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); })
      .then(function (j) {
        if (j && j.error) { throw new Error(j.error); }
        onOk(j);
      })
      .catch(function (e) { onErr(e); });
  }

  /* ---------- filters ---------- */

  function loadFilters() {
    fetchJson(API + "?action=filters", function (j) {
      var loc = $("fLocation");
      (j.locations || []).forEach(function (l) {
        var o = document.createElement("option");
        o.value = l.uuid;
        o.textContent = l.name;
        loc.appendChild(o);
      });
      var et = $("fEncType");
      (j.encounterTypes || []).forEach(function (t) {
        var o = document.createElement("option");
        o.value = t.uuid;
        o.textContent = t.name;
        et.appendChild(o);
      });
    }, function (e) { console.error("filters failed", e); setSummary("Failed to load filters"); });
  }

  function collectState() {
    state.from = $("fFrom").value;
    state.to = $("fTo").value;
    state.location = $("fLocation").value;
    state.encounterType = $("fEncType").value;
  }

  function setSummary() {
    var parts = [];
    if (state.from && state.to) {
      parts.push(state.from + " \u2192 " + state.to);
    }
    parts.push(state.location ? $("fLocation").selectedOptions[0].textContent : "All health centers");
    parts.push(state.encounterType ? $("fEncType").selectedOptions[0].textContent : "All encounter types");
    $("filterSummary").textContent = parts.join(" \u00B7 ");
  }

  /* ---------- render ---------- */

  function render(data) {
    dataCache = data;
    setSummary();
    renderKpis(data.kpis);
    renderTrend(data.monthly);
    renderDonut("chartType", data.byType || [], "Encounters by type");
    renderLocation(data);
    renderAge(data.age || []);
    renderSex(data.sex || []);
    renderTable(data.byType || []);
  }

  function renderKpis(kpis) {
    (kpis.items || []).forEach(function (k) {
      var card = document.querySelector('.kpi[data-kpi="' + k.key + '"]');
      if (!card) return;
      $("kpi-" + k.key).textContent = Number(k.value).toLocaleString();
      var dEl = $("delta-" + k.key);
      var d = Number(k.delta);
      if (d === 0) {
        dEl.textContent = "no change";
        dEl.className = "kpi-delta";
      } else {
        var up = d > 0;
        dEl.textContent = (up ? "\u25B4 " : "\u25BE ") + (up ? "" : "+") + d.toFixed(1) + "% vs prior period";
        dEl.className = "kpi-delta " + (up ? "up" : "down");
      }
    });
  }

  function chartBase() {
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { labels: { color: "#66788a", boxWidth: 12, font: { size: 11 } } }
      }
    };
  }

  function renderTrend(monthly) {
    var ctx = $("chartTrend");
    if (charts.trend) charts.trend.destroy();
    charts.trend = new Chart(ctx, {
      type: "line",
      data: {
        labels: (monthly || []).map(function (m) { return m.ym; }),
        datasets: [
          { label: "Encounters", data: (monthly || []).map(function (m) { return m.encounters; }),
            borderColor: "#0e6f4e", backgroundColor: "rgba(14,111,78,0.12)", fill: true, tension: 0.35, borderWidth: 2, pointRadius: 3 },
          { label: "Patients seen", data: (monthly || []).map(function (m) { return m.patients; }),
            borderColor: "#e8a13c", backgroundColor: "rgba(232,161,60,0.12)", fill: true, tension: 0.35, borderWidth: 2, pointRadius: 3 }
        ]
      },
      options: Object.assign(chartBase(), {
        scales: {
          x: { grid: { display: false }, ticks: { color: "#66788a", maxRotation: 45, autoSkip: true } },
          y: { beginAtZero: true, grid: { color: "#edf1f4" }, ticks: { color: "#66788a" } }
        }
      })
    });
  }

  function renderDonut(canvasId, rows, title) {
    var ctx = $(canvasId);
    var chartId = canvasId;
    if (charts[chartId]) charts[chartId].destroy();
    var labels = (rows || []).map(function (r) { return r.label; });
    var values = (rows || []).map(function (r) { return r.count; });
    charts[chartId] = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: labels.length ? labels : ["No data"],
        datasets: [{ data: labels.length ? values : [1], backgroundColor: labels.join(",") === "No data" ? ["#e2e8f0"] : PALETTE, borderWidth: 2, borderColor: "#ffffff" }]
      },
      options: Object.assign(chartBase(), {
        cutout: "62%",
        plugins: Object.assign(chartBase().plugins, {
          legend: { position: "bottom", labels: { color: "#66788a", boxWidth: 12, font: { size: 11 }, padding: 8 } }
        })
      })
    });
  }

  function renderLocation(data) {
    var ctx = $("chartLocation");
    var id = "chartLocation";
    if (charts[id]) charts[id].destroy();
    var rows, title;
    if (state.location) {
      rows = data.sex || [];
      title = "Patients by sex at selected center";
    } else {
      rows = data.byLocation || [];
      title = "Encounters by health center";
    }
    $("chartLocTitle").textContent = title;
    if (rows.length === 0) rows = [{ label: "No data", count: 1 }];
    charts[id] = new Chart(ctx, {
      type: "bar",
      data: {
        labels: rows.map(function (r) { return r.label; }),
        datasets: [{
          data: rows.map(function (r) { return r.count; }),
          backgroundColor: rows[0].label === "No data" ? ["#e2e8f0"] : PALETTE,
          borderRadius: 5
        }]
      },
      options: Object.assign(chartBase(), {
        indexAxis: "y",
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { color: "#edf1f4" }, ticks: { color: "#66788a" } },
          y: { grid: { display: false }, ticks: { color: "#66788a" } }
        }
      })
    });
  }

  function renderAge(rows) {
    var ctx = $("chartAge");
    if (charts.chartAge) charts.chartAge.destroy();
    var order = ["0-4", "5-9", "10-14", "15-19", "20-24", "25-34", "35-49", "50+", "Unknown"];
    var by = {};
    (rows || []).forEach(function (r) { by[r.label] = r.count; });
    var labels = order.filter(function (g) { return by[g] !== undefined; });
    if (!labels.length) labels = ["No data"];
    charts.chartAge = new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [{ label: "Patients", data: labels.map(function (g) { return by[g] || 0; }),
          backgroundColor: PALETTE, borderRadius: 5 }]
      },
      options: Object.assign(chartBase(), {
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { color: "#66788a" } },
          y: { beginAtZero: true, grid: { color: "#edf1f4" }, ticks: { color: "#66788a" } }
        }
      })
    });
  }

  function renderSex(rows) {
    var ctx = $("chartSex");
    if (charts.chartSex) charts.chartSex.destroy();
    var labels = (rows || []).map(function (r) { return r.label; });
    var values = (rows || []).map(function (r) { return r.count; });
    if (!labels.length) { labels = ["No data"]; values = [1]; }
    charts.chartSex = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: labels,
        datasets: [{ data: values, backgroundColor: labels.length === 1 && labels[0] === "No data" ? ["#e2e8f0"] : PALETTE, borderWidth: 2, borderColor: "#fff" }]
      },
      options: Object.assign(chartBase(), {
        cutout: "62%",
        plugins: Object.assign(chartBase().plugins, {
          legend: { position: "bottom", labels: { color: "#66788a", boxWidth: 12, font: { size: 11 }, padding: 8 } }
        })
      })
    });
  }

  function renderTable(rows) {
    var tbody = document.querySelector("#typeTable tbody");
    tbody.innerHTML = "";
    var total = (rows || []).reduce(function (s, r) { return s + r.count; }, 0);
    if (!total) {
      var tr = document.createElement("tr");
      var td = document.createElement("td");
      td.colSpan = 3;
      td.textContent = "No encounters in the selected period.";
      td.className = "num";
      tr.appendChild(td);
      tbody.appendChild(tr);
      return;
    }
    (rows || []).forEach(function (r) {
      var tr = document.createElement("tr");
      tr.appendChild(td(r.label));
      tr.appendChild(td(Number(r.count).toLocaleString(), "num"));
      tr.appendChild(td((r.count / total * 100).toFixed(1) + "%", "num share"));
      tbody.appendChild(tr);
    });
  }

  function td(text, cls) {
    var cell = document.createElement("td");
    if (cls) cell.className = cls;
    cell.textContent = text;
    return cell;
  }

  /* ---------- data loading ---------- */

  function loadCounts() {
    setLoading(true);
    var url = API + "?action=counts";
    if (state.from) url += "&from=" + state.from;
    if (state.to) url += "&to=" + state.to;
    if (state.location) url += "&location=" + state.location;
    if (state.encounterType) url += "&encounterType=" + state.encounterType;
    fetchJson(url, function (j) { render(j); setLoading(false); },
      function (e) { setLoading(false); setSummary(); console.error(e); setSummary("Data failed to load: " + e.message); });
  }

  function setLoading(on) {
    document.querySelectorAll(".kpis, .charts, .table-card").forEach(function (el) {
      el.classList.toggle("loading", on);
    });
  }

  /* ---------- CSV export ---------- */

  function exportCsv() {
    var rows = (dataCache && dataCache.byType) || [];
    var lines = ["report,value"];
    lines.push("period," + state.from + " to " + state.to);
    lines.push("health center," + ($("fLocation").selectedOptions[0] ? $("fLocation").selectedOptions[0].textContent : "All"));
    lines.push("encounter type," + ($("fEncType").selectedOptions[0] ? $("fEncType").selectedOptions[0].textContent : "All"));
    lines.push("");
    lines.push("encounter type,encounters,share %");
    var total = rows.reduce(function (s, r) { return s + r.count; }, 0);
    rows.forEach(function (r) {
      lines.push(r.label + "," + r.count + "," + (total ? (r.count / total * 100).toFixed(1) : "0"));
    });
    var blob = new Blob(["\uFEFF" + lines.join("\n")], { type: "text/csv;charset=utf-8" });
    var a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "phu360reporting-" + (state.from || "all") + "_" + (state.to || "all") + ".csv";
    document.body.appendChild(a);
    a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 200);
  }

  /* ---------- init ---------- */

  function init() {
    Chart.defaults.font.family = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    var d = defaultRange();
    $("fFrom").value = d.from;
    $("fTo").value = d.to;
    state.from = d.from;
    state.to = d.to;

    loadFilters();

    $("btnApply").addEventListener("click", function () {
      collectState();
      if (!state.from || !state.to) { setSummary("Select a period"); return; }
      loadCounts();
    });
    $("btnReset").addEventListener("click", function () {
      $("fLocation").value = "";
      $("fEncType").value = "";
    });
    $("btnCsv").addEventListener("click", exportCsv);

    loadCounts();
  }

  document.addEventListener("DOMContentLoaded", init);
})();