# Prototype Fidelity v0.1

Use this reference when a user provides a prototype, screenshot, Figma frame, HTML prototype, design image, or asks that implementation match an existing visual reference.

## Capability Name

This is **prototype-to-implementation fidelity**. In practical frontend work it combines:

- visual grounding;
- design-to-code;
- image/screenshot-to-code;
- visual regression testing;
- design QA.

## Rule

Do not treat the prototype as inspiration. Treat it as an implementation contract unless the user explicitly approves deviations.

## Accepted Prototype Sources

- Screenshot or image
- Figma link/export
- HTML/CSS prototype
- Existing static page
- Product video or interaction recording
- PDF or slide mockup

## Required Artifact: prototype.md

Create or update `prototype.md` with:

- Source: file path, URL, Figma frame, or screenshot path
- Target viewports: desktop/mobile/tablet sizes
- Visible text inventory: exact text that must appear
- Layout and component inventory: major regions and component mapping
- Assets: images, icons, logos, generated assets, fonts
- Interaction states: hover, modal, tabs, menus, disabled/loading/error states
- Responsive behavior: how layout changes by viewport
- Accepted deviations: differences the user explicitly allows
- Fidelity risks: areas likely to drift from the prototype

## Open Stage

Ask only for missing fidelity-critical facts:

- Which screen/frame is canonical?
- Which viewport size should be matched first?
- Are exact colors, typography, spacing, and copy required?
- Is interaction behavior part of the prototype, or only visual layout?
- Are deviations allowed to fit the existing design system?

## Design Stage

Include a visual fidelity plan:

- source capture path;
- target screenshot paths;
- viewport list;
- component mapping to existing codebase components;
- design token mapping;
- assets to extract, generate, or replace;
- design QA method.

If a product-design image-to-code skill is available and the source is a screenshot/mockup, route implementation through it. If not, manually follow this reference.

## Build Stage

- Implement the prototype structure before polishing behavior.
- Preserve exact visible wording unless the user approves changes.
- Use existing design system components when they can match the prototype.
- Do not silently redesign spacing, hierarchy, colors, or layout.
- Record intentional deviations in `prototype.md` and `verify.md`.

## Verify Stage

Prototype mode requires visual evidence:

1. Run the app locally.
2. Capture screenshot(s) at the target viewport(s).
3. Compare against the source prototype.
4. Record mismatches by severity:
   - P0: wrong screen, missing major section, unreadable layout
   - P1: major layout, typography, or interaction mismatch
   - P2: noticeable spacing/color/content mismatch
   - P3: minor polish
5. Fix P0/P1/P2 before marking prototype fidelity as passed, unless the user explicitly accepts a deviation.

Record in `verify.md`:

- source screenshot/prototype path;
- implementation screenshot path;
- viewport size;
- comparison result;
- accepted deviations;
- final fidelity result: `passed`, `accepted-with-deviations`, or `blocked`.

## Useful Tools

- Browser screenshot capture
- Playwright or equivalent e2e runner
- Storybook screenshots
- Pixel diff tools
- Manual side-by-side visual QA

The exact tool is less important than having comparable screenshots and recorded findings.
