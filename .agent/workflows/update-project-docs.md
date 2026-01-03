---
description: Update the repository's design document and README based on recent changes
---

First, read the following Markdown files which contain project's documentation:

 - README.md (entry point for humans and AI agents)
 - DESIGN.md (detailed design document)
 - .agent/rules/overview.md (entry point for Antigravity AI agents)
 - CLAUDE.md (entry point for Claude Code AI agents)

Note: `.agent/rules/overview.md` should be an exact copy of `CLAUDE.md` to ensure consistency between agent contexts. After updating `CLAUDE.md`, copy its content to `.agent/rules/overview.md`.

Use `git log` to review recent changes since the document's last update (as indicated by the `last_updated_commit` field in the frontmatter of the file).

Make surgical updates, if necessary, to the project's documentation to keep the documents up to date with changes to the project's architecture, folder structure, feature set, technical implementation, or instructions. Maintain the existing style and structure of each document if possible.

At the beginning of each file, in the YAML frontmatter, update or add the `last_updated_commit` field with the HEAD commit ID:
```yaml
---
last_updated_commit: <HEAD commit ID>
---
```
Ensure you preserve any other existing frontmatter fields.