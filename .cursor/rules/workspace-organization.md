# Workspace Organization Rules

## Temporary Files Location

All temporary files, logs, references, plans, and markdown files created during AI-assisted development **must** be created in the `.cursor/temp` directory.

### Files That Must Go in `.cursor/temp`

- **Temporary files**: Any temporary files created during development sessions
- **Log files**: Test logs, build logs, execution logs, etc.
- **Reference files**: Reference documents, performance measurements, analysis results
- **Plan files**: Development plans, task lists, analysis documents
- **Markdown files**: Any temporary markdown files (analysis, notes, documentation drafts)

### Examples

✅ **Correct locations:**
- `.cursor/temp/performance-analysis.md`
- `.cursor/temp/test-results.log`
- `.cursor/temp/plan.md`
- `.cursor/temp/references.md`
- `.cursor/temp/build-log.txt`

❌ **Incorrect locations:**
- Root directory temporary files (unless they are build artifacts)
- Any other ad-hoc temporary locations

### Naming Conventions

- Use descriptive, lowercase filenames with appropriate extensions
- Use hyphens or underscores for multi-word names
- Examples: `performance-analysis.md`, `test-results.log`, `build-plan.md`

### Cleanup

- Temporary files in `.cursor/temp` are meant to be disposable
- They will be cleaned manually

