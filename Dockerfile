# ALIVE APPLE — Reference Only
# ⚠️  This Dockerfile is documentation only. It does NOT build the iOS app.
#
# iOS IPA builds REQUIRE:
# - macOS environment (Xcode, XcodeGen)
# - GitHub Actions runner (see .github/workflows/)
# - Apple Developer credentials
#
# This container is useful for:
# - Documentation/reference
# - Model downloads via HuggingFace CLI
# - Project exploration
#
# To build the actual iOS app:
# 1. Push to GitHub
# 2. GitHub Actions runs build.sh on macOS runner
# 3. IPA is signed and available for testing/distribution
#
# This is NOT a Docker build target; use docker/local development workflow instead.

FROM alpine:3.21

LABEL org.opencontainers.image.title="ALIVE APPLE"
LABEL org.opencontainers.image.description="iPhone 16 on-device AI - 4 models, fully offline"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/chris23597/ALIVE-APPLE"

RUN apk add --no-cache git bash curl python3 py3-pip

WORKDIR /alive-apple
COPY . .

RUN pip3 install --break-system-packages huggingface_hub

CMD ["sh", "-c", "echo 'ALIVE APPLE v1.0 — iPhone 16 on-device AI' && echo '' && echo 'Project files:' && ls -la && echo '' && echo '⚠️  This container is for reference only.' && echo 'To build IPA: push to GitHub, Actions auto-builds on macOS runner.' && echo 'To download models: pip install huggingface_hub && hf download REPO FILE --local-dir .'"]
