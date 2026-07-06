# Policy Pack: frontend-prototype

## Purpose

Treat visual references and user-facing UI behavior as implementation contracts.

## Load When

Load for screenshots, Figma frames, HTML prototypes, mockups, visual parity requests, responsive UI, or user-facing interaction changes.

## Added Gates

- Create or update `prototype.md` for visual-reference work.
- Record target viewports, visible text, layout hierarchy, interaction states, assets, and accepted deviations.
- Verify with screenshots or a documented manual visual check at matching viewport sizes.
- Fix P0/P1 visual mismatches before passing verification unless the user accepts deviations.

## Required Evidence

- Source reference path or URL.
- Implementation screenshot path or manual check notes.
- Viewport size.
- Mismatch list and final fidelity result: `passed`, `accepted-with-deviations`, or `blocked`.

## Skip Policy

Visual verification can be skipped only for non-visual UI internals or when the user explicitly accepts a manual non-screenshot check.
