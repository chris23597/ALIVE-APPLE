---
name: edit-file-discipline
description: >
  MANDATORY. Stop edit_file thrashing — the #1 live failure in CodeWhale sessions.
  Always read before edit; re-read after every successful edit; max 2 failed searches then write_file.
user-invocable: false
---

# Edit-file discipline (live failure fix)

## Why this exists

TUI logs (2026-07-14 → 2026-07-16) keep showing:

| Error | Cause |
|-------|--------|
| `Refusing edit_file … has not been read in this session` | Called `edit_file` / `apply_patch` without a prior `read_file` in **this** session |
| `Search string not found` | Invented or stale search text after a previous edit shifted lines |

These waste turns and stall multi-file jobs (ChatPanel, orchestrator, api.ts, Launch-ALIVE-Pro).

## Hard rules (every edit)

1. **Read first**  
   Before **any** `edit_file` / `apply_patch` on path P:  
   `read_file(P)` (or scoped offset/limit that covers the exact edit site).  
   **Session-scoped:** a read in an older session does **not** count.

2. **Copy search strings from the tool result**  
   Paste the exact bytes from the latest `read_file` output.  
   Do **not** reconstruct from memory, prior patches, or “what I think is there”.

3. **Re-read after every successful edit on the same file**  
   After edit N lands, the file changed. For edit N+1 on the same path:  
   `read_file` again (at least the region you will touch) → then edit.

4. **Max 2 failed `edit_file` on the same path**  
   After 2× “search not found” or refuse:
   - Stop patch thrashing  
   - Prefer **`write_file` full rewrite** if change is large / multi-hunk  
   - Or re-scope with `grep_files` + one precise surgical patch  

5. **Size rule (same as yolo-excellence)**  

| Change | Tool |
|--------|------|
| ≤10 lines, one site | `edit_file` / `apply_patch` after fresh read |
| New file or >30% of file | `write_file` complete contents |
| Many scattered hunks in one component | One `write_file`, not 10 patches |

## Recovery template (when tool returns the refuse/search error)

```
1) read_file(path) covering the edit region
2) copy EXACT search from result
3) edit_file once
4) if fail again → write_file OR re-grep and stop looping
```

## NEVER

- Chain 4+ `edit_file` on the same file without re-reads between them  
- Edit a file you only “know” from grep match lines (grep is not a full read)  
- Blame the user or claim tools are broken for these two errors — they are agent discipline  

## Learn

If you still thrash: append one line to `.codewhale/JUDGE.md` Permanent fixes + tighten this skill.
