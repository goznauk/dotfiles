# Config Editor UX Review

Date: 2026-05-20

## Executive Summary

This pass focused only on the Config editor step. The main UX problem was that the page presented the full block/code list as the primary surface, while the real selected-block editor was buried below thousands of pixels on mobile and squeezed beside a heavy dark panel on desktop.

Implemented changes make the selected block the primary editing surface, demote the block list into a compact navigator, collapse output previews by default, improve mobile file/block selection, and reduce keyboard noise. Config generation, installer logic, package logic, and generated shell content were not changed.

Measured improvements:

- `.zshrc` code-line buttons: 113 baseline to 0 final.
- Max measured Config tab stops: 288 baseline to 136 final.
- `.zshrc` selected-block top at 320x568: 6496px baseline to 325px final.
- Screenshot matrix horizontal overflow: 0 baseline, 0 final.
- Screenshot matrix console issues: 0 baseline, 0 final.

## Agent Roster

- Orchestrator Agent: kept scope limited to Config UX, selected implementation batches, and owned validation.
- Screenshot Critic Agent: reviewed baseline and after screenshots for hierarchy, density, wrapping, and mobile usability.
- Product/UI Designer Agent: converted critique into selected-block-primary layout recommendations.
- Frontend Developer Agent: implemented scoped React and CSS changes in `chooser/src/App.tsx` and `chooser/src/styles.css`.
- Accessibility Agent: reviewed keyboard flow, tab-stop volume, names, switches, tab semantics, and textarea labels.
- Responsive QA Agent: checked viewport matrix behavior and before/after reachability.
- Validation Agent role: run by Orchestrator through lint, build, repo check, browser DOM/console smoke, and screenshot manifests.

## Local App Command

Started the local app with:

```bash
npm run dev
```

Working directory:

```bash
/Users/goznauk/Projects/DBCodex/dotfiles/chooser
```

Local URL:

```text
http://127.0.0.1:5173/?view=configs&config=zshrc&os=ubuntu&theme=light
```

## Viewports Tested

Required Config matrix:

- 320x568
- 375x667
- 390x844
- 414x896
- 768x1024
- 1024x768
- 1280x800
- 1440x900
- 1600x1000

Extra Config state:

- `.gitconfig` at 320x568, 768x1024, and 1440x900.

## Screenshots Captured

Baseline:

- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-320x568.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-375x667.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-390x844.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-414x896.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-768x1024.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-1024x768.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-1280x800.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-1440x900.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-zshrc-1600x1000.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-gitconfig-320x568.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-gitconfig-768x1024.png`
- `.tmp/config-editor-screenshots/cycle1-baseline-configs-gitconfig-1440x900.png`

After batch 1:

- `.tmp/config-editor-screenshots/cycle2-after-batch1-configs-zshrc-320x568.png`
- `.tmp/config-editor-screenshots/cycle2-after-batch1-configs-zshrc-768x1024.png`
- `.tmp/config-editor-screenshots/cycle2-after-batch1-configs-zshrc-1440x900.png`
- `.tmp/config-editor-screenshots/cycle2-after-batch1-configs-gitconfig-320x568.png`
- Full matrix manifest: `.tmp/config-editor-screenshots/cycle2-after-batch1-manifest.json`

Final:

- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-320x568.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-375x667.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-390x844.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-414x896.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-768x1024.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-1024x768.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-1280x800.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-1440x900.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-zshrc-1600x1000.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-gitconfig-320x568.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-gitconfig-768x1024.png`
- `.tmp/config-editor-screenshots/cycle3-final-configs-gitconfig-1440x900.png`
- Full final manifest: `.tmp/config-editor-screenshots/cycle3-final-manifest.json`

## Baseline Problems

- Mobile top density was too high. At 320x568, the viewport showed navigation, the title, two rows of config tabs, the Powerlevel10k card, and only the top of the dark `.zshrc` block list.
- Selected-block details were buried. At 320x568, `detailTop` was 6496px for `.zshrc`; at 768x1024 it was 4294px.
- The dark code panel dominated the Config step and made the actual edit card feel secondary.
- Every block repeated `Up`, `Down`, and `On` controls, creating visual noise.
- Every displayed code line was a button. `.zshrc` produced 113 line buttons and a max measured 288 tab stops.
- Long shell lines wrapped awkwardly in the dark list and made line numbers misleading.
- Output preview was visually heavy on desktop and effectively hidden on tablet/mobile.
- Config tabs wrapped on narrow screens in a loose two-row button group.
- Textareas were unlabeled for assistive technology.

## Agent Discussion Log

### Cycle 1: Baseline Review

Screenshot Critic: At 320x568, the first viewport gives users controls, not editing context. The selected-block detail is absent, and the dark `.zshrc` panel begins at the fold. At 1440x900, three columns are cramped and the dark block list visually outweighs the selected editor.

Designer: Agreed. The selected block should become the main editor. The block list should become a light navigator with title, kind, enabled state, and line count. Output previews should be collapsed by default.

Accessibility Agent: The line-button model is the highest priority issue. Raw code text in 113 tabbable buttons creates noisy keyboard and screen-reader flow. Textareas need accessible labels. Tabs should use tab semantics instead of `aria-pressed`.

Responsive QA Agent: Below 1100px, the selected editor is pushed below the full block list. Output actions are also pushed too far down on tablet/mobile. Mobile tabs and code wrapping are fragile.

Frontend Developer Agent: Proposed a scoped master/detail refactor in `ConfigBlockEditor`: remove per-line buttons, keep one selector per block, move enable/move/reset controls to the selected-block panel, and leave config generation functions untouched.

Orchestrator Decision: Approved batch 1 because it fixed the largest UX and accessibility problems without touching config generation or installer behavior.

Implemented in batch 1:

- Selected-block detail rendered first as the primary editor.
- Dark code pane replaced with a light compact block navigator.
- Per-line buttons removed.
- Repeated per-block `Up`, `Down`, and `On` controls moved to selected-block controls.
- Block editor and generated output textareas labeled.
- Config output copy actions moved above collapsed preview details.
- Desktop tablist semantics and arrow-key support added.

Deferred from batch 1:

- Mobile file dropdown and adaptive textarea sizing, because those were better judged from after screenshots.

### Cycle 2: After Batch 1 Review

Screenshot Critic: Batch 1 was a clear net win. Code-line buttons dropped to 0, and selected editor reachability improved. Remaining issues: mobile horizontal config tabs were weakly discoverable, short blocks still had oversized textareas, and long editable lines were clipped without a clear affordance.

Designer: Keep the selected-block-primary layout. Add only a small second batch: mobile file selection, mobile block selection, adaptive textarea rows, and a clearer tab affordance for larger screens.

Accessibility Agent: Add roving `tabIndex` to the tablist, make the editor a real `tabpanel`, use stable switch names, and expose block actions as a named group or block-specific button names.

Responsive QA Agent: Mobile selected editor is now reachable, but the file selector should be more explicit on narrow screens. Compact the Powerlevel10k card on mobile and add a block selector so users do not have to scroll to the block list to switch blocks.

Frontend Developer Agent: Batch 2 can be done with local React/CSS only: native selects on small screens, adaptive textarea rows, stable ARIA names, and tabpanel wiring.

Orchestrator Decision: Approved a narrow polish pass. Deferred mobile output duplication because collapsed output copy actions were already successful and duplicating them would add more top density.

Implemented in batch 2:

- Mobile-only Config file dropdown.
- Mobile-only selected block dropdown.
- Adaptive editor rows based on selected block line count.
- Soft wrapping for editable block textarea display, without changing stored content.
- Roving `tabIndex` for desktop config tabs.
- `role="tabpanel"` and `aria-labelledby` for the editor panel.
- Stable selected-block switch name.
- Named block action group and block-specific button labels.
- Compact mobile preference card.

Deferred from batch 2:

- Duplicating output copy actions near the Config heading. It would add top density, and the collapsed output aside already keeps copy actions visible on desktop.
- A wrap-lines toggle. Soft wrapping in the editor addressed readability with less UI weight.

## Design Decisions

- Selected block is the primary editing surface.
- Block list is a navigator, not a code editor.
- Generated file and write command previews are secondary and collapsed by default.
- Mobile uses native selects for file and block selection because they are compact and discoverable.
- Editable block content uses soft wrapping to make long lines readable while preserving textarea value.
- Generated file preview remains horizontally scrollable to preserve exact output inspection.
- Off blocks use explicit visual state rather than opacity.

## Changes Implemented

- Updated `chooser/src/App.tsx`.
- Updated `chooser/src/styles.css`.
- No config definitions, command builder logic, catalog data, installer scripts, or generated shell content were changed.

Major UI changes:

- Reordered Config editor into selected detail first, compact block list second.
- Removed line-level interactive buttons from the block list.
- Added selected-block enable switch and move/reset controls in the detail panel.
- Added line-count, order, kind, and on/off summaries to block cards.
- Moved output copy actions above collapsed preview details.
- Added mobile Config file and block selectors.
- Made Config tabs a proper roving tablist on larger screens.
- Made block editor height adapt to content.

## Accessibility Impact

- Removed 113 `.zshrc` code-line buttons.
- Reduced max measured Config tab stops from 288 to 136.
- Added accessible labels for block editor and generated file textareas.
- Added `role="tablist"`, `role="tab"`, roving `tabIndex`, and `role="tabpanel"`.
- Replaced state-changing switch name with stable switch name plus `aria-checked`.
- Added block-specific action button labels.
- Added `role="group"` for selected-block actions.
- Mobile file/block selects provide simpler keyboard and screen-reader access than a clipped horizontal tab row.

## Responsive Impact

- At 320x568, selected-block detail moved from 6496px below the section to 325px.
- At 768x1024, selected-block detail moved from 4294px to 279px.
- At 390x844, selected-block detail moved from 5942px to 300px.
- Final matrix reported no horizontal overflow at all required viewport sizes.
- Mobile Config file selector uses a native dropdown, avoiding hidden tabs.
- Mobile block selector allows block switching before the long block list.
- Desktop retains tabs and side output, but the center editor now has clearer priority.

## Validation Results

Commands run:

```bash
npm --prefix chooser run lint
npm --prefix chooser run build
./scripts/check.sh
```

Results:

- `npm --prefix chooser run lint`: passed.
- `npm --prefix chooser run build`: passed.
- `./scripts/check.sh`: passed.
- Command builder tests inside `./scripts/check.sh`: passed.
- Shell syntax checks inside `./scripts/check.sh`: passed.
- JSON checks inside `./scripts/check.sh`: passed.
- ASCII text policy inside `./scripts/check.sh`: passed.
- Git diff whitespace inside `./scripts/check.sh`: passed.

Environment note:

- `./scripts/check.sh` reported `WARN: tmux server could not start; skipping .tmux.conf load check.` The script still completed successfully and reported `Repository checks passed`.

Browser and screenshot validation:

- Headless Chrome final screenshot matrix: passed with 0 horizontal overflow and 0 console issues.
- In-app Browser DOM/console smoke: passed with no warning/error logs.
- In-app Browser role-click smoke attempt timed out in the browser automation runtime. A DOM/console smoke check completed afterward and found no app console errors, no horizontal overflow, `role="tabpanel"`, one active tab in tab order, and 0 code-line buttons.

## Browser Console Findings

- Baseline screenshot matrix: 0 console issues.
- Batch 1 screenshot matrix: 0 console issues.
- Final screenshot matrix: 0 console issues.
- Final in-app Browser DOM smoke: no warning or error logs.

## Commits Created

- `d2cc3ab fix: simplify config editor layout`
- `4f81569 fix: polish config editor mobile controls`
- `docs: add config editor UX review` for this report.

## Deferred Items

- Mobile/tablet duplicate output copy actions near the Config heading: deferred to avoid adding density after output previews were already collapsed.
- Explicit wrap-lines toggle: deferred because soft wrapping the editable block textarea solved the immediate readability issue with less UI.
- Full drag-and-drop accessibility for block reordering: existing drag behavior was preserved, but keyboard reordering remains through selected-block move buttons.
- More advanced block list virtualization or search: unnecessary for the current block counts.

## Remaining Risks

- Mobile block switching is now easier via a select, but the full block list still appears below the editor and can be long for `.zshrc`.
- Generated file preview is collapsed and horizontally scrollable; users who need deep output inspection still need to open it.
- The final report references `.tmp` screenshots that are intentionally not committed.
- Browser automation role-click timed out once, so final interaction evidence relies on DOM/console Browser smoke plus the headless Chrome screenshot matrix.

## Recommended Next Steps

- Consider keyboard-accessible drag/drop or a dedicated reorder list if block reordering becomes a primary workflow.
- Consider a compact output action strip for tablet only if users report difficulty finding copy actions after editing.
- Add component-level tests if the chooser gains a React testing setup; current validation relies on existing command tests, build/lint, browser DOM checks, and screenshot matrices.
