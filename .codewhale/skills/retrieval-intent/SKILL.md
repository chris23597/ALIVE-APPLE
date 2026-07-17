---
name: retrieval-intent
description: >
  GLOBAL (every project). Wrong citations, RAG/search noise, "hello" attached to unrelated docs,
  knowledge base false positives. Gate retrieval to real questions; require topical overlap.
user-invocable: true
---

# Retrieval intent (global — any project with search/RAG/docs)

## Product rules (apply everywhere)

1. **Greetings and bare statements are not knowledge queries.**  
   `hello`, `hi`, `thanks`, `ok` → answer as the assistant only. **No** docs, manuals, KB, or "sources".

2. **Retrieve only for information-seeking asks**  
   Questions, how-to, domain terms, multi-word topical content.

3. **Hits must share real content with the query**  
   Term overlap / relevance threshold — not "top of index" noise.

4. **Never invent citations** when nothing relevant was retrieved.

## Analysis loop (any codebase)

1. Find where retrieval runs (search, RAG, embed, vector DB, keyword index)
2. Find where results are attached to the model prompt
3. Add an **intent gate before retrieve**
4. Filter weak hits (score + token overlap)
5. Separate prompt path for chitchat (no sources section)
6. Tests: greeting → 0 sources; real domain question → sources with overlap

## Generic gate sketch

```text
if is_chitchat(message) or not is_information_seeking(message):
    skip_retrieval; empty citations; chitchat prompt
else:
    hits = retrieve(message)
    hits = filter_by_term_overlap_and_score(message, hits)
    prompt_with_sources(hits)
```

## Proof

- Unit test: `hello` → retrieve false / cites 0  
- Unit test: domain question → retrieve true / cites ≥ 1 with shared terms  

## ALIVE-specific

If workspace is ALIVE, also use **rag-intent** and `backend/app/agents/query_intent.py`.
