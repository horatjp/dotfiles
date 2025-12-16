---
applyTo: "**/*.ts,**/*.tsx,**/*.js,**/*.jsx,**/*.css,**/*.scss,**/*.html,**/*.vue,**/*.svelte"
---

# Frontend Contribution Guide

## Scope

-   Applies to any web UI assets, dashboards, or helper pages stored in this repository.
-   Prioritize portable solutions that work offline and without heavy build pipelines.
-   Keep styling and behavior consistent with the existing dotfiles aesthetic.

## Tooling Preferences

-   Default to TypeScript with strict compiler options when JavaScript is required.
-   Use plain CSS or lightweight utility classes; avoid large UI frameworks unless already in use.
-   Keep dependencies minimal and pin exact versions in configuration files.

## File Organization

-   Group related scripts, styles, and HTML fragments in self-contained folders named after the feature.
-   Place shared utilities under a `lib/` or `utils/` subdirectory and document their usage in a README.
-   Preserve existing naming conventions; avoid whole-sale reorganizations unless previously discussed.

## Coding Standards

-   Favor functional components and composition over inheritance-like patterns.
-   Use meaningful ARIA attributes and semantic HTML, validating with an accessibility checker when possible.
-   Add concise comments only where intent is non-obvious or a workaround is required.

## Testing and Verification

-   Provide simple reproduction steps and, where practical, add Playwright or Vitest coverage.
-   Include manual verification notes covering accessibility, responsive layouts, and theme compatibility.
-   Suggest `npm run lint` or equivalent commands after any structural change.

## Change Management

-   Explain user-facing impact in pull request descriptions and reference supporting documentation.
-   Update screenshots or recordings whenever UI changes are significant.
-   Avoid introducing breaking changes to shared components without a migration note.
