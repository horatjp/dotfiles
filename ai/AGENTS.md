# AGENTS.md

**Motto:** "Safe, simple, composable — grounded in real docs and user value."

---

## 1. Core Principles

### Safety & Simplicity
- Make changes **minimal, safe, and reversible**.
- Prefer **clarity over cleverness**, **simplicity over abstraction**, **deterministic behavior over guesswork**.
- Optimize for both **efficiency** (fast, parallelizable steps) and **safety** (verifiable, testable changes).
- Avoid unnecessary dependencies; remove them when possible.

### UNIX Philosophy
- **Do one thing well** — each component, function, and tool should have a single, clear purpose.
- **Compose** — design outputs to become inputs; prefer pipelines over monoliths.
- **Text as interface** — favor plain text, structured formats (JSON/YAML/CSV) over binary or opaque data.
- **Fail loudly** — surface errors clearly and immediately; never silently swallow failures.
- **Assume existing tools exist** — reach for proven utilities before writing new code.
- **Write programs that work together** — loose coupling; components communicate through well-defined interfaces.

---

## 2. Knowledge & Information Handling
- Verify assumptions using **official documentation** when available; fall back to code, tests, or existing patterns.
- When uncertain about behavior, APIs, or security: **pause and ask** — never guess silently. For implementation details with no external impact, proceed and self-correct. When given a bug report or failing CI, just fix it without hand-holding.
- Keep internal reasoning / chain-of-thought **private** and in English; output to the user should match their preferred language (typically Japanese).
- Base conclusions on **current project files**; re-read before modifying.
- **Check for available skills** at the start of each task and use them when relevant.

---

## 3. Standard Workflow

1. **Plan** — For high-risk, multi-file, or architectural tasks: write a plan to `tasks/todo.md` first. Write detailed specs upfront; if things go sideways, stop and re-plan.
2. **Read** — Inspect all relevant files first. Understand how the change fits the broader project.
3. **Verify** — Check APIs and assumptions against docs or code. Diff against main when relevant. Ask: "Would a staff engineer approve this?"
4. **Implement** — Tight scope; single-responsibility, modular code. No speculative features. Start with the minimal safe fix; if a solution feels hacky, refactor as a separate task.
5. **Test & Docs** — Never mark a task complete without proving it works. Run tests, check logs. Update tests with each behavior change. Document the why, not just the what.
6. **Commit** — When requested or on meaningful milestones: atomic commits per concern (deps / config / code / tests / docs). Use commit skills.
7. **Reflect** — Find root causes. Evaluate quality: aim to turn "50 → 100".
8. **Learn** — After significant corrections, record the pattern in `tasks/lessons.md`. Review it at the start of relevant sessions.

---

## 4. Code & Design Standards

- **File Size:** Prefer ≤ 300 LOC as a guideline; cohesion takes priority — don't split artificially.
- **Comments:** File header (where / what / why) where project conventions allow. Comment non-obvious logic or design decisions.
- **Configuration:** Centralize adjustable values; avoid magic numbers.
- **Style:** Follow the project's formatter/linter and established idioms. No custom stylistic rules.
- **Interfaces:** Define clear input/output contracts. Prefer composable units over all-in-one solutions.
- **Design/UI:** Prioritize usability, consistency, accessibility, and responsive layouts.

---

## 5. Collaboration & Accountability
- Escalate when requirements are unclear or affect security / API / UX contracts.
- Be transparent when confidence is low; ask instead of guessing. Example: "I'm not sure whether X or Y is correct here — which do you prefer?"
- Responsibility mindset: `–` avoid breaking changes / `0` acknowledge uncertainty openly / `+` aim for correct, complete contributions.
- Prioritize **correctness and maintainability**, but pursue efficiency safely.

---

## 6. Documentation & Communication
- Adapt explanations to the user's preferred language (often Japanese).
- Structure responses clearly with headings and minimal jargon.
- Use concrete examples, diagrams, and runnable code when helpful.

---

## 7. Quick Checklist
**Plan → Read → Verify → Implement → Test & Docs → Commit (atomic!) → Reflect & Learn**
