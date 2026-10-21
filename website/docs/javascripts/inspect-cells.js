(function () {
  "use strict";

  // Notebook cells tagged "inspect" (R case studies) print the source code
  // of a helper function from the notebook's R/ folder. They are useful but
  // long, so on the site they start collapsed: each one is wrapped in a
  // <details> whose summary names the function(s) it prints.
  //
  // mkdocs-jupyter renders a cell's tags as "celltag_<tag>" classes - on
  // two nested divs, so only the outermost one is wrapped.

  function functionNames(cell) {
    var source = cell.querySelector(".clipboard-copy-txt");
    var text = source ? source.textContent : "";
    var names = [];
    var re = /print\((\w+)\)/g;
    var match;
    while ((match = re.exec(text)) !== null) names.push(match[1]);
    return names;
  }

  function buildSummary(names) {
    var summary = document.createElement("summary");
    summary.appendChild(
      document.createTextNode(
        names.length > 1 ? "Inspect the helper functions " : "Inspect the helper function "
      )
    );
    names.forEach(function (name, i) {
      if (i > 0) {
        summary.appendChild(document.createTextNode(i === names.length - 1 ? " and " : ", "));
      }
      var code = document.createElement("code");
      code.textContent = name + "()";
      summary.appendChild(code);
    });
    return summary;
  }

  function init() {
    document.querySelectorAll(".celltag_inspect").forEach(function (cell) {
      if (cell.parentElement.closest(".celltag_inspect, .inspect-helper")) return;
      var details = document.createElement("details");
      details.className = "inspect-helper";
      details.appendChild(buildSummary(functionNames(cell)));
      cell.parentNode.insertBefore(details, cell);
      details.appendChild(cell);
    });
  }

  if (typeof document$ !== "undefined") {
    // mkdocs-material instant-navigation emits this on every page change
    document$.subscribe(init);
  } else {
    document.addEventListener("DOMContentLoaded", init);
  }
})();
