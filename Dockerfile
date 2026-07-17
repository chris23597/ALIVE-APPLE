# ALIVE APPLE — Dockerfile
# Multi-purpose: builds iOS IPA via XcodeGen + serves project
# Stage 1: Documentation + project snapshot (portable)
FROM alpine:3.21 AS project

LABEL org.opencontainers.image.title="ALIVE APPLE"
LABEL org.opencontainers.image.description="iPhone 16 on-device AI - 4 models, fully offline"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/chris23597/ALIVE-APPLE"

RUN apk add --no-cache git bash curl python3 py3-pip

WORKDIR /alive-apple
COPY . .

# Pre-install huggingface CLI for model download capability
RUN pip3 install --break-system-packages huggingface_hub

# Default: show project structure + instructions
CMD ["sh", "-c", "echo 'ALIVE APPLE v1.0 — iPhone 16 on-device AI' && echo '' && echo 'Project files:' && ls -la && echo '' && echo 'To build IPA: push to GitHub, Actions auto-builds on macOS runner.' && echo 'To download models: pip install huggingface_hub && hf download REPO FILE --local-dir .'"]
