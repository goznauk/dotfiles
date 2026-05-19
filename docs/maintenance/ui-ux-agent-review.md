# UI UX Agent Review

Date: 2026-05-20
Branch: new
App: chooser
Local URL: http://127.0.0.1:5173/
Report owner: Orchestrator Agent

## Executive Summary

This review used the local chooser app, the in-app Browser runtime, headless
Google Chrome through CDP, screenshot manifests, DOM checks, console checks,
and specialist subagents to improve the user-facing setup chooser.

The main outcomes:

- The Run step now prioritizes the command panel on mobile and tablet layouts.
- The command panel exposes the Bootstrap command and Copy action much earlier
  on narrow screens.
- The package search no-results state now has explicit visible feedback.
- Copy success and copy failure now use visible status feedback plus live
  announcement text.
- Keyboard focus, selected-state semantics, switch names, modal focus handling,
  and touch target sizing were improved.
- The missing favicon console error was fixed.
- Final Chrome screenshot validation found zero horizontal overflow and zero
  console warnings/errors.

## Agent Roster

- Orchestrator Agent: sequenced the workflow, managed risk, chose improvement
  batches, kept the decision log, and integrated final changes.
- Screenshot Critic Agent: reviewed baseline and after screenshots, cited
  concrete viewport/state problems, and challenged regressions.
- Product/UI Designer Agent: translated visual criticism into concrete layout,
  hierarchy, copy, and information architecture recommendations.
- Frontend Developer Agent: implemented scoped React/CSS/HTML changes and ran
  focused checks after each coherent group.
- Accessibility Agent: reviewed focus states, accessible names, selected-state
  semantics, modal behavior, live status, touch targets, and screen-reader
  clarity.
- Responsive QA Agent: identified breakpoint, mobile density, touch target,
  wrapping, and overflow risks.
- Validation Agent: recommended the validation suite and final evidence:
  root checks, app checks, browser smoke, console checks, screenshots, and git
  status.

## Local App Command

The app was already running and answering on the expected local URL:

```sh
http://127.0.0.1:5173/
```

The repository command for starting it is:

```sh
npm --prefix chooser run dev
```

## Browser And Screenshot Method

The in-app Browser runtime successfully handled navigation, DOM snapshots, and
console reads. Its screenshot endpoint timed out on `Page.captureScreenshot`,
including a single default viewport capture. The workflow documented that
blocker and switched to the next-best method: local Google Chrome headless via
CDP, driven by an ignored temporary script under `.tmp/`.

Temporary screenshot directory:

```text
.tmp/ui-ux-screenshots/
```

Screenshots were not committed.

## Viewports Tested

Required viewport matrix:

- 320x568
- 375x667
- 390x844
- 414x896
- 768x1024
- 1024x768
- 1280x800
- 1440x900
- 1600x1000

## States Tested

Default matrix:

- Default landing target state:
  `cycle1-baseline-default-target-{viewport}.png`
  `cycle2-after-batch1-default-target-{viewport}.png`
  `cycle3-after-batch2-default-target-{viewport}.png`
  `cycle4-final-default-target-{viewport}.png`

Additional states captured at 320x568, 768x1024, and 1440x900:

- Package catalog with base group open:
  `cycle*-packages-base-open-{viewport}.png`
- Package catalog after clearing package selections:
  `cycle*-packages-empty-selection-{viewport}.png`
- Package catalog no-results search:
  `cycle*-packages-no-results-{viewport}.png`
- Toolchains in dark theme:
  `cycle*-toolchains-dark-{viewport}.png`
- Config editor zshrc state:
  `cycle*-configs-zshrc-{viewport}.png`
- Summary and generated command state:
  `cycle*-summary-default-{viewport}.png`
- Preview summary state in dark theme:
  `cycle*-summary-macos-dark-{viewport}.png`
- Target change modal:
  `cycle*-target-modal-{viewport}.png`
- Copy status after command copy:
  `cycle*-summary-copy-status-{viewport}.png`

Manifest files:

- `.tmp/ui-ux-screenshots/cycle1-baseline-manifest.json`
- `.tmp/ui-ux-screenshots/cycle2-after-batch1-manifest.json`
- `.tmp/ui-ux-screenshots/cycle3-after-batch2-manifest.json`
- `.tmp/ui-ux-screenshots/cycle4-final-manifest.json`

## Baseline Problems Found

- Mobile Run page hid the primary command and Copy action below the fold:
  `cycle1-baseline-summary-default-320x568.png`,
  `cycle1-baseline-summary-default-768x1024.png`.
- Package search no-results state was visually silent:
  `cycle1-baseline-packages-no-results-1440x900.png`,
  `cycle1-baseline-packages-no-results-768x1024.png`.
- Mobile package screenshots did not prove catalog states because the package
  catalog was below the command-step cards:
  `cycle1-baseline-packages-no-results-320x568.png`.
- Copy status was not visible in the current viewport:
  `cycle1-baseline-summary-copy-status-320x568.png`,
  `cycle1-baseline-summary-copy-status-1440x900.png`.
- Summary package chips were clipped in the Run page:
  `cycle1-baseline-summary-default-1440x900.png`.
- Config editor had dense multi-column content and awkward code wrapping:
  `cycle1-baseline-configs-zshrc-1440x900.png`,
  `cycle1-baseline-configs-zshrc-320x568.png`.
- Package tree rows had decorative branch lines that added visual noise:
  `cycle1-baseline-packages-base-open-768x1024.png`.
- Target modal title wrapped awkwardly on mobile:
  `cycle1-baseline-target-modal-320x568.png`.
- The app produced a favicon 404 console error in Chrome.

## Agent Discussion Log

### Cycle 1: Baseline Review

Screenshot Critic:
At 320x568 the Run page shows only the Summary card; the Bootstrap command and
Copy button are not visible. At 1440x900 the package no-results state shows an
empty gap with no message. The package chip list looks clipped on desktop.

Designer:
Agree. The Run step should prioritize the command, not the audit summary. Add
clearer top-page orientation, clarify the section nav as a flow, and move
command metadata into a less dominant structure.

Accessibility Agent:
Focus states are missing. Active choices are visual only. Switches announce as
only "On" or "Off". The target modal needs focus management, Escape close, and
focus return. Copy success needs live feedback.

Responsive QA:
The 1024x768 breakpoint is risky because two-column grids persist too long.
Mobile touch targets are too small. The target modal needs max-height and
scrolling.

Frontend Developer:
Can implement the first batch with CSS, small JSX state semantics, and modal
keyboard handling. No command-generation behavior needs to change.

Orchestrator Decision:
Approved batch 1 because it is low risk and improves navigation, mobile Run
priority, and accessibility semantics without touching backend or installer
logic.

Implemented:

- Hero support copy on wider screens.
- Step-number nav on tablet/desktop, hidden again on narrow mobile after
  screenshot review showed crowding.
- `aria-current`, `aria-pressed`, semantic switch labels, focus-visible styles,
  copy live region text, modal focus trap, Escape close, focus restore, and
  larger mobile touch targets.
- Summary command panel ordered first below 1100px.

Deferred:

- No-results state, visible copy toast, package row noise, and package chip
  clipping were deferred to batch 2 because they were separate user feedback
  surfaces.

### Cycle 2: First Improvement Pass

Screenshot Critic:
Batch 1 improved desktop orientation and mobile Run ordering. It regressed
mobile top density because the helper copy pushed controls down on 320px. The
Run page still did not show the actual command block in the first mobile
viewport.

Designer:
Agree. Hide the helper copy on phone widths and make the Run page more action
first by reducing metadata before the command. Replace visually silent states
with explicit feedback.

Accessibility Agent:
Batch 1 fixed many core accessibility problems. Remaining issues: repeated
"Change" buttons need contextual names and expanded state, active config block
selection is visual only, the dialog warning needs `aria-describedby`, and
repeated copy announcements need a DOM text change.

Responsive QA:
The 320px nav is readable after hiding number chips. The package catalog state
needs screenshots scrolled to the catalog area on mobile so the state can be
verified.

Frontend Developer:
Can implement with a visible no-results block, fixed status toast, command
details disclosure, removed package branch decoration, contextual ARIA labels,
and screenshot-script state scrolling.

Orchestrator Decision:
Approved batch 2. It resolves P0/P1 findings from screenshots and closes the
remaining low-risk accessibility review items.

Implemented:

- Visible package no-results state.
- Fixed visible status toast for copy success/failure plus live announcement
  counter for repeated copies.
- Command metadata moved below command output into `Review command details`.
- Package tree branch decoration removed.
- Selected package chips no longer use a clipped max-height scroller.
- Contextual `aria-label`, `aria-expanded`, and `aria-controls` for Change/Done
  strategy controls.
- `aria-pressed` for active config block buttons.
- Dialog warning associated with `aria-describedby`.
- Phone hero helper copy hidden.

Deferred:

- Full config editor redesign was deferred as too broad and risky for this pass.
  The current changes improved touch/accessibility without restructuring the
  editor.

### Cycle 3: Second Improvement Pass

Screenshot Critic:
`cycle3-after-batch2-summary-default-320x568.png` now shows the command panel,
package count, Bootstrap command header, and Copy button in the first viewport.
`cycle3-after-batch2-packages-no-results-320x568.png` and 1440x900 now show a
clear no-results message. Modal title no longer wraps as "Change target OS".

Designer:
Agree. The primary task is now clearer. Remaining visual issues are lower
priority: the config editor is still dense, and package command output remains
long because the generated command itself is long.

Accessibility Agent:
The outstanding low-risk accessibility issues from cycle 2 were addressed.
Remaining risk is mainly that the config line list still has many tabbable code
line buttons. A roving focus pattern would be a larger behavior change and was
not taken in this pass.

Validation Agent:
Focused lint and build pass. Browser smoke confirms the no-results state is in
the DOM and Chrome console logs are clean except for a favicon 404.

Orchestrator Decision:
Approved a final micro-batch to eliminate the favicon 404 and reach clean
browser console validation.

Implemented:

- Data-URI favicon in `chooser/index.html`.

Deferred:

- Roving focus for config lines and a deeper config editor layout redesign.
  Both are valuable but higher-risk than the requested careful polish pass.

### Cycle 4: Final Validation

Validation Agent:
Final Chrome CDP matrix captured 36 screenshots with zero horizontal overflow
and zero console warnings/errors:
`.tmp/ui-ux-screenshots/cycle4-final-manifest.json`.

Orchestrator:
No more implementation changes selected. Remaining issues are either speculative
or require larger interaction redesign.

## Design Decisions Made

- Keep the chooser as a single scrolling flow.
- Improve the section tabs as a wizard-like flow on wider screens, but hide
  number chips on narrow phones where they crowd the nav.
- Make Run command output visually primary on mobile and tablet.
- Keep command-generation behavior unchanged.
- Prefer a fixed status toast over an in-flow message so copy feedback remains
  visible even after deep-link scrolling.
- Remove package tree decoration because it implied hierarchy without useful
  interaction.
- Keep the config editor structure but improve keyboard/touch semantics.
- Fix the favicon 404 rather than documenting it as an acceptable console issue.

## Changes Implemented

- `chooser/src/App.tsx`
  - Added step metadata for nav labels.
  - Added active-state ARIA on nav, target buttons, version buttons, config
    tabs, strategy choices, config blocks, and code line buttons.
  - Added contextual switch names.
  - Added target modal keyboard handling and warning association.
  - Added package search no-results state.
  - Added visible copy status and more reliable live announcements.
  - Moved command details into a disclosure below command blocks.
  - Removed package row branch markup.

- `chooser/src/styles.css`
  - Added focus-visible styling.
  - Improved header sizing and mobile density.
  - Improved mobile/touch hit areas.
  - Improved modal sizing and scrolling.
  - Reordered the Run command panel on narrow layouts.
  - Added empty-state, command-details, and status-toast styles.
  - Removed selected-package-list clipping.

- `chooser/index.html`
  - Added an inline favicon to remove the Chrome favicon 404.

## Accessibility Improvements

- Global visible focus states for anchors, buttons, inputs, selects, textareas,
  and summaries.
- Semantic switch names instead of repeated "On" and "Off" button names.
- `aria-current` for active flow nav step.
- `aria-pressed` for selected button-style options.
- Modal focus moves inside on open, traps Tab, closes on Escape, and restores
  focus to the opener.
- Modal warning is associated with `aria-describedby`.
- Copy feedback is available visually and through a live region.
- Repeated copy announcements force a DOM text change.
- Code line and config block selections expose selected state.
- Mobile action controls have larger tap targets.

## Responsive Improvements

- Main grids collapse at 1100px instead of 980px.
- The Run command panel is ordered before summary details below 1100px.
- Phone hero copy is hidden to keep the first actionable card higher.
- Modal has max-height and internal scrolling.
- Package catalog screenshots now scroll to the catalog panel on mobile states.
- Agent/tool rows and selected strategy cards stack on mobile.
- Long package/tool code labels wrap safely.

## Browser Console Findings

- Baseline, cycle 2, and cycle 3 each had one Chrome network error:
  `/favicon.ico` returned 404.
- Final cycle fixed that with an inline favicon.
- Final Chrome CDP manifest:
  `cycle4-final`: 36 screenshots, 0 horizontal overflow, 0 console issues.

## Validation Results

Focused checks already passed during implementation:

- `npm --prefix chooser run lint`
- `npm --prefix chooser run build`
- `git diff --check`
- Browser DOM/console smoke through the in-app Browser runtime.
- Chrome CDP screenshot matrix for cycles 1, 2, 3, and 4.

Final root check result:

- `./scripts/check.sh` passed.
- The check printed one environment warning:
  `tmux server could not start; skipping .tmux.conf load check.`

## Commits Created

- `30ea093 fix: improve chooser responsive accessibility`
- `33ba506 fix: polish chooser command and package feedback`
- `eb959a5 fix: add chooser favicon`

The report update will be committed separately as documentation.

## Deferred Items

- Roving focus for the config line list. This would reduce tab-stop volume but
  is a larger interaction pattern change.
- Larger config editor redesign. The editor remains dense, especially with long
  shell content, but a structural redesign risks changing established behavior.
- Dedicated visual regression tests. The repository does not currently include a
  Playwright setup.
- Persistent committed screenshots. Screenshots are large temporary QA artifacts
  and `.tmp/` is ignored.

## Known Risks

- Clipboard success depends on browser permissions. In the headless Chrome
  copy-status state, clipboard write fails and the new visible failure toast is
  shown. Normal browsers with clipboard permission should show the corresponding
  copied toast.
- The config editor still has many interactive code line buttons. It is more
  accessible than baseline, but not a full code-editor accessibility pattern.
- macOS, Amazon Linux, and RHEL remain preview targets; this pass did not change
  installer support.

## Recommended Next Steps

- Add a small Playwright or browser-smoke script to the repo if visual QA will
  become routine.
- Consider a dedicated config editor redesign with roving focus and a clearer
  source/preview split.
- Consider a compact command preview mode that summarizes the generated command
  while still allowing full copy.
- Add an app-level QA route or query parameter for package search and copy
  status states to make future screenshot capture simpler.
