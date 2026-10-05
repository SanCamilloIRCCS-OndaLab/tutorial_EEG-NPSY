(function () {
  "use strict";

  // Each entry is a group of "same content, different language" pages,
  // identified by their directory name (the last segment of the clean
  // URL) - NOT a full path, so this works whether the site is served at
  // the domain root or under a sub-path (e.g. GitHub Pages project sites).
  var PAGE_GROUPS = [
    {
      Python: "case_study_1_notebook",
      R: "case_study_1_notebook_r",
    },
  ];

  function currentGroup() {
    var segments = window.location.pathname.split("/").filter(Boolean);
    var here = segments[segments.length - 1];
    for (var i = 0; i < PAGE_GROUPS.length; i++) {
      var group = PAGE_GROUPS[i];
      for (var lang in group) {
        if (group[lang] === here) {
          return { group: group, current: lang };
        }
      }
    }
    return null;
  }

  // In the sidebar, only the *other* language's entry needs hiding - the
  // current page's own entry is never a plain outbound link (Material
  // renders it as the active item), so matching by href is only reliable
  // for the ones we actually want to hide.
  function hideSiblingNavEntries(group, current) {
    Object.keys(group).forEach(function (lang) {
      if (lang === current) return;
      var dirName = group[lang];
      document.querySelectorAll(".md-nav__link[href]").forEach(function (link) {
        if (link.getAttribute("href").indexOf(dirName + "/") !== -1) {
          var li = link.closest(".md-nav__item");
          if (li) li.style.display = "none";
        }
      });
    });
  }

  function buildWidget(group, current) {
    var widget = document.createElement("div");
    widget.className = "lang-switch";
    widget.setAttribute("role", "group");
    widget.setAttribute("aria-label", "Choose a language");

    Object.keys(group).forEach(function (lang) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "lang-switch__btn";
      if (lang === current) btn.classList.add("lang-switch__btn--active");
      btn.textContent = lang;
      btn.addEventListener("click", function () {
        // relative link, sibling directory - works under any base path
        if (lang !== current) window.location.href = "../" + group[lang] + "/";
      });
      widget.appendChild(btn);
    });

    return widget;
  }

  function init() {
    var found = currentGroup();
    if (!found) return;

    hideSiblingNavEntries(found.group, found.current);

    var existing = document.querySelector(".lang-switch");
    if (existing) existing.remove();
    document.body.appendChild(buildWidget(found.group, found.current));
  }

  if (typeof document$ !== "undefined") {
    // mkdocs-material instant-navigation emits this on every page change
    document$.subscribe(init);
  } else {
    document.addEventListener("DOMContentLoaded", init);
  }
})();
