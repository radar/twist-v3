import "../css/app.css";
import "../css/tailwind-compiled.css";
import "../css/fontawesome/fontawesome.css";
import "../css/fontawesome/solid.css";
import "../css/fontawesome/regular.css";
import "../css/pygments.css";

import * as Turbo from "@hotwired/turbo";

// Frames only: leave ordinary links and forms alone so the rest of the app keeps
// doing full page loads. Anything that should go through Turbo opts in with
// data-turbo="true".
Turbo.config.drive.enabled = false;

// Note pills (see app/templates/elements/_element.html.erb) point at an empty
// turbo-frame sitting under their paragraph, so the first click has Turbo load
// the note panel into it. Clicking again should close the panel, which Turbo has
// no concept of — that part is on us.
//
// Capture phase on `document` matters: Turbo listens on `document.documentElement`
// while bubbling, so this runs first and its preventDefault() is what keeps Turbo
// from re-fetching a panel we're only closing.
document.addEventListener(
  "click",
  (event) => {
    if (!(event.target instanceof Element)) return;

    const pill = event.target.closest("[data-note-toggle]");
    if (!pill) return;

    // Let the browser have modified clicks (open in new tab, etc.) and anything
    // that isn't a plain left click. Turbo ignores these too.
    if (event.defaultPrevented) return;
    if (event.which > 1 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;

    const frame = document.getElementById(pill.dataset.turboFrame);
    if (!frame) return; // No panel on this page — follow the link as normal.

    // `busy` covers the click that lands while the first fetch is still in
    // flight: hide it now, and it stays hidden when the response arrives.
    const open = frame.innerHTML.trim() !== "" || frame.hasAttribute("busy");

    if (open) {
      // Hide rather than empty the frame, so a half-written note survives a
      // stray click on the pill.
      event.preventDefault();
      frame.hidden = !frame.hidden;
    } else {
      frame.hidden = false; // Turbo takes it from here.
    }

    pill.setAttribute("aria-expanded", String(!frame.hidden));
  },
  true
);
