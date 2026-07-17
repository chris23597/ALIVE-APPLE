---
name: secrets-never-ship
description: >
  Never commit or paste secrets: .env, API keys, tokens, Docker hub passwords.
  Safe-ship denylist. If a key appears in logs, rotate.
user-invocable: true
---

# Secrets never ship

## Never stage / commit / put on USB retail stick

- `.env`, `.env.local`, `*.pem`, `id_rsa`, credentials  
- `CLOUD_API_KEY`, `OPENAI_API_KEY`, `HF_TOKEN`, npm tokens  
- `data/conversations/*.db`, user chat logs  
- Full `models/*.gguf` to GitHub  

## If exposed in chat/logs

1. Stop echoing the value.  
2. Tell user to **rotate** the key at provider.  
3. Remove from git history if committed (user must confirm force ops).  

## Tools

- `alive-ship` / `codewhale-ship-policy` SAFE allowlist  
- Retail USB: no real API keys (see `alive-portable-usb`)
