# Policy Packs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a policy-pack architecture so Spec to Ship can stay general-purpose while supporting optional strict/team/domain engineering rules.

**Architecture:** Keep `SKILL.md` short and route to a new policy index. Store individual packs as Markdown assets under `assets/policy-packs/`, and add a shell lint script that fails validation when a pack is not indexed.

**Tech Stack:** Markdown documentation and Bash validation scripts.

---

### Task 1: Policy Pack Assets

**Files:**
- Create: `skill/spec-to-ship/references/policy-packs.md`
- Create: `skill/spec-to-ship/assets/policy-packs/default-light.md`
- Create: `skill/spec-to-ship/assets/policy-packs/strict-team.md`
- Create: `skill/spec-to-ship/assets/policy-packs/frontend-prototype.md`
- Create: `skill/spec-to-ship/assets/policy-packs/backend-api.md`
- Create: `skill/spec-to-ship/assets/policy-packs/database-change.md`
- Create: `skill/spec-to-ship/assets/policy-packs/security-sensitive.md`

- [ ] **Step 1: Create the policy-pack index**

Add trigger rules, composition rules, precedence, and a complete pack list to `policy-packs.md`.

- [ ] **Step 2: Create the bundled packs**

Each pack gets purpose, trigger conditions, added gates, required evidence, and skip policy.

- [ ] **Step 3: Check discoverability**

Run: `rg "default-light|strict-team|frontend-prototype|backend-api|database-change|security-sensitive" skill/spec-to-ship/references/policy-packs.md`

Expected: every pack name appears.

### Task 2: Skill Routing

**Files:**
- Modify: `skill/spec-to-ship/SKILL.md`

- [ ] **Step 1: Add policy pack to the mental model**

Mention that policy packs layer stricter rules on top of the core workflow.

- [ ] **Step 2: Add policy loading rules**

Add guidance for reading `references/policy-packs.md` during open/design and loading only triggered packs.

- [ ] **Step 3: Preserve progressive disclosure**

Confirm `SKILL.md` points to the index instead of copying all policy rules inline.

### Task 3: Validation

**Files:**
- Create: `skill/spec-to-ship/scripts/spec-to-ship-policy-lint.sh`
- Modify: `scripts/validate.sh`

- [ ] **Step 1: Add policy lint script**

The script should fail when a Markdown file under `assets/policy-packs/` is not listed in `references/policy-packs.md`.

- [ ] **Step 2: Wire lint into validation**

Call the script from `scripts/validate.sh` after skill frontmatter checks.

- [ ] **Step 3: Run validation**

Run: `& 'C:\Program Files\Git\bin\bash.exe' scripts/validate.sh`

Expected: `Validation passed.`

### Task 4: Public Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/USAGE.md`
- Modify: `docs/DESIGN_RATIONALE.md`
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Update README**

Add policy packs to key mechanisms and quick usage.

- [ ] **Step 2: Update architecture and rationale**

Document why packs keep the workflow general while allowing strict rules.

- [ ] **Step 3: Update usage and roadmap**

Explain how users select or layer policy packs and what is deferred to future configuration work.

### Task 5: Spec to Ship Evidence

**Files:**
- Modify: `spec-to-ship/changes/add-policy-packs/tasks.md`
- Modify: `spec-to-ship/changes/add-policy-packs/verify.md`
- Modify: `spec-to-ship/changes/add-policy-packs/release.md`

- [ ] **Step 1: Check off completed tasks**

Update `tasks.md` as implementation completes.

- [ ] **Step 2: Record verification**

Write exact validation command and result in `verify.md`.

- [ ] **Step 3: Record release readiness**

Document low-risk release impact, rollback, monitoring, and security/privacy notes.
