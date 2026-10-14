(function () {
  "use strict";

  // Sections with more than one page, where the top-nav dropdown
  // (overrides/partials/tabs-item.html) is a fast jump but a plain
  // "what else is here" list at the bottom of the page is still useful
  // (and is the only such link on mobile, where tabs don't show at all).
  var SECTIONS = [
    {
      dir: "getting_started",
      pages: [
        { slug: "installation", title: "Installation" },
        { slug: "data", title: "Data" },
        { slug: "structure", title: "Repository Structure" },
      ],
    },
    {
      dir: "about",
      pages: [
        { slug: "citation", title: "Citation" },
        { slug: "contributing", title: "Contributing" },
        { slug: "changelog", title: "Changelog" },
      ],
    },
  ];

  function currentPage() {
    var segments = window.location.pathname.split("/").filter(Boolean);
    var here = segments[segments.length - 1];
    var dir = segments[segments.length - 2];
    for (var i = 0; i < SECTIONS.length; i++) {
      if (SECTIONS[i].dir === dir) {
        return { section: SECTIONS[i], here: here };
      }
    }
    return null;
  }

  function buildNav(section, here) {
    var wrapper = document.createElement("div");
    wrapper.className = "section-nav";

    var heading = document.createElement("p");
    heading.className = "section-nav__heading";
    heading.textContent = "More in this section";
    wrapper.appendChild(heading);

    var list = document.createElement("div");
    list.className = "section-nav__links";
    section.pages.forEach(function (p) {
      if (p.slug === here) return;
      var a = document.createElement("a");
      a.className = "md-button";
      a.href = "../" + p.slug + "/"; // sibling directory, same as lang-switch.js
      a.textContent = p.title;
      list.appendChild(a);
    });
    wrapper.appendChild(list);

    return wrapper;
  }

  function init() {
    var existing = document.querySelector(".section-nav");
    if (existing) existing.remove();

    var found = currentPage();
    if (!found) return;

    var article = document.querySelector(".md-content__inner");
    if (!article) return;
    article.appendChild(buildNav(found.section, found.here));
  }

  if (typeof document$ !== "undefined") {
    document$.subscribe(init);
  } else {
    document.addEventListener("DOMContentLoaded", init);
  }
})();
