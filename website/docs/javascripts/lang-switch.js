(function () {
  "use strict";

  // Each entry is a case study whose code pages live at
  // case_studies/<parent>/<python|r>/ - siblings under the same parent
  // directory. "python"/"r" are no longer globally unique directory
  // names (both case studies use them), so matching needs the parent
  // segment too, not just the last one.
  var PAGE_GROUPS = [
    { parent: "case_study_1", langs: { Python: "python", R: "r" } },
    { parent: "case_study_2", langs: { Python: "python", R: "r" } },
  ];

  var ICONS = {
    Python: "python.svg",
    R: "r.svg",
    Matlab: "matlab.svg",
  };

  // Script file extension per language, matching the plain-script files
  // published next to each notebook (case_studies/scripts/<parent>_<lang>.<ext>).
  var SCRIPT_EXT = {
    Python: "py",
    R: "R",
  };

  function currentGroup() {
    var segments = window.location.pathname.split("/").filter(Boolean);
    var here = segments[segments.length - 1];
    var parent = segments[segments.length - 2];
    for (var i = 0; i < PAGE_GROUPS.length; i++) {
      var group = PAGE_GROUPS[i];
      if (group.parent !== parent) continue;
      for (var lang in group.langs) {
        if (group.langs[lang] === here) {
          return { langs: group.langs, current: lang };
        }
      }
    }
    return null;
  }

  var DOWNLOAD_ICON =
    '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" focusable="false">' +
    '<path fill="currentColor" d="M12 16.5l-5.5-5.5 1.41-1.41L11 12.67V4h2v8.67l3.09-3.08L17.5 11z"/>' +
    '<path fill="currentColor" d="M5 18h14v2H5z"/>' +
    "</svg>";

  // Pill switcher with a single generic "download" icon folded in,
  // divided by a thin rule - reads as one component ("choose a
  // language, or just grab the code") instead of a separate link
  // floating next to it. The icon doesn't download anything itself
  // (there are two things to choose from, notebook or script) - it just
  // jumps down to the two labelled buttons at the end of the page.
  function buildWidget(langs, current) {
    var widget = document.createElement("div");
    widget.className = "lang-switch";
    widget.setAttribute("role", "group");
    widget.setAttribute("aria-label", "Choose a language");

    Object.keys(langs).forEach(function (lang) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "lang-switch__btn";
      if (lang === current) btn.classList.add("lang-switch__btn--active");

      if (ICONS[lang]) {
        var icon = document.createElement("img");
        icon.className = "lang-switch__icon";
        icon.src = "../../icons/" + ICONS[lang]; // see note below
        icon.alt = "";
        icon.setAttribute("aria-hidden", "true");
        btn.appendChild(icon);
      }
      btn.appendChild(document.createTextNode(lang));

      btn.addEventListener("click", function () {
        // relative link, sibling directory - works under any base path
        if (lang !== current) window.location.href = "../" + langs[lang] + "/";
      });
      widget.appendChild(btn);
    });

    var download = document.createElement("button");
    download.type = "button";
    download.className = "lang-switch__download";
    download.setAttribute("title", "Download the code");
    download.setAttribute("aria-label", "Download the code");
    download.innerHTML = DOWNLOAD_ICON;
    download.addEventListener("click", function () {
      var target = document.querySelector(".download-code-button");
      if (target) target.scrollIntoView({ behavior: "smooth", block: "start" });
    });
    widget.appendChild(download);

    return widget;
  }

  function buildDownloadButtons(parent, nbFile, scriptFile, scriptLabel) {
    var wrapper = document.createElement("div");
    wrapper.className = "download-code-button";

    var nbLink = document.createElement("a");
    nbLink.className = "md-button";
    nbLink.href = nbFile;
    nbLink.setAttribute("download", parent + "_" + nbFile);
    nbLink.textContent = "Download the notebook (.ipynb)";
    wrapper.appendChild(nbLink);

    // The plain-script version lives in a separate case_studies/scripts/
    // folder: mkdocs-jupyter's own sibling-file copying only handles one
    // notebook per source directory, and this one has two (python.ipynb
    // and r.ipynb).
    var scriptLink = document.createElement("a");
    scriptLink.className = "md-button";
    scriptLink.href = "../../scripts/" + parent + "_" + scriptFile;
    scriptLink.setAttribute("download", parent + "_" + scriptFile);
    scriptLink.textContent = "Download the script (" + scriptLabel + ")";
    wrapper.appendChild(scriptLink);

    return wrapper;
  }

  // Pill switcher goes right after the page's H1, not floating - so it
  // reads as part of the page (like a sub-title), and there's no sidebar
  // entry to hide/show: the nav only ever lists one plain "Code" link.
  // The download buttons go at the very end of the article, after all
  // notebook content.
  function insertWidget(widget, downloadButtons) {
    var article = document.querySelector(".md-content__inner");
    if (!article) return;
    var h1 = article.querySelector("h1");
    if (!h1) return;
    h1.insertAdjacentElement("afterend", widget);
    article.appendChild(downloadButtons);
  }

  function init() {
    document.querySelectorAll(".lang-switch, .download-code-button").forEach(function (el) {
      el.remove();
    });

    var found = currentGroup();
    if (!found) return;

    var segments = window.location.pathname.split("/").filter(Boolean);
    var parent = segments[segments.length - 2];
    var langSlug = found.langs[found.current];
    var nbFile = langSlug + ".ipynb";
    var scriptExt = SCRIPT_EXT[found.current] || "txt";
    var scriptFile = langSlug + "." + scriptExt;
    var scriptLabel = "." + scriptExt;

    // Icon path ("../../icons/<lang>.svg") is relative to the current
    // page, which is always case_studies/<case_study>/<lang>/ - two
    // levels up reaches case_studies/icons/. Safe to hardcode because
    // this only ever runs once currentGroup() has matched one of those
    // pages.
    insertWidget(
      buildWidget(found.langs, found.current),
      buildDownloadButtons(parent, nbFile, scriptFile, scriptLabel)
    );
  }

  if (typeof document$ !== "undefined") {
    // mkdocs-material instant-navigation emits this on every page change
    document$.subscribe(init);
  } else {
    document.addEventListener("DOMContentLoaded", init);
  }
})();
