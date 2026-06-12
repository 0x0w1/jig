# Knowledges Ingest Guardrails

## Scope

- Default to incremental import into `raw/`.
- Inspect `raw/` before choosing a destination path.
- Do not edit `wiki/` directly from another project unless the user explicitly requests it.
- Do not run full raw/wiki review unless the user explicitly asks for `/resync`.
- Do not run Graphify repeatedly for each raw file. Let `/sync` run `graphify . --update` once at the end.

## Privacy

Do not import:

- `.env` contents
- API keys, tokens, private keys, passwords, cookies, or session values
- private customer data
- database dumps
- logs containing personal data

If durable knowledge depends on sensitive material, write a sanitized summary and record only the non-sensitive source path.

## Cost And Time Control

Use changed files first:

```bash
git status --short
git diff --name-only
git rev-parse --short HEAD
```

Avoid:

- reading the full source repository
- re-summarizing unchanged documents
- full Graphify rebuilds during quick ingest
- importing more than a small batch without user confirmation

Defer and report before running `/sync` when:

- more than 5 raw files would be imported
- source content is larger than roughly 20,000 words
- the update requires comparing many existing wiki pages
- Graphify update is expected to be slow or costly
