# Add MLX Swift packages in Xcode (enable real inference)

ALIVE APPLE already compiles in **demo mode** without these packages (`#if canImport(MLXLLM)`).  
When you add the packages below, **the same app** loads real on-device models (Phi-4 Mini, SmolVLM2).

**Do this on a Mac with Xcode.** CI can stay package-free; your device build uses MLX.

---

## Packages to add

| URL | Products / libraries to check |
|-----|-------------------------------|
| `https://github.com/ml-explore/mlx-swift-lm` | **MLXLLM**, **MLXLMCommon**, **MLXHuggingFace** (and any required transitive MLX products Xcode offers) |
| `https://github.com/huggingface/swift-huggingface` | **HuggingFace** (default product) |
| `https://github.com/huggingface/swift-transformers` | **Tokenizers** / transformers product Xcode lists |

Exact product checkboxes vary by package version — enable anything needed to resolve:

```swift
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace
import Tokenizers
```

---

## Step-by-step (Xcode UI)

### 1. Open the project

1. On Mac, open the repo folder in Terminal or Finder.  
2. Prefer: generate then open  
   ```bash
   brew install xcodegen   # if needed
   cd /path/to/ALIVE-APPLE
   xcodegen generate --spec project.yml
   open "ALIVE APPLE.xcodeproj"
   ```  
3. Or **File → Open** → `ALIVE APPLE.xcodeproj`.

### 2. Add package dependencies

1. In Xcode menu: **File → Add Package Dependencies…**  
   (older Xcode: **File → Add Packages…**)  
2. In the search field (top right of the sheet), paste the **first URL**:  
   `https://github.com/ml-explore/mlx-swift-lm`  
3. **Dependency Rule:**  
   - Prefer **Up to Next Major Version** from the latest tag Xcode shows, **or**  
   - **Branch: `main`** if tags fail to resolve.  
4. Click **Add Package**.  
5. On **Choose Package Products**:  
   - Tick **MLXLLM**  
   - Tick **MLXLMCommon**  
   - Tick **MLXHuggingFace**  
   - Target: **ALIVE APPLE** (your app target)  
6. Click **Add Package**.

Repeat **File → Add Package Dependencies…** for:

7. `https://github.com/huggingface/swift-huggingface`  
   - Add product **HuggingFace** → target **ALIVE APPLE**  
8. `https://github.com/huggingface/swift-transformers`  
   - Add **Tokenizers** (and any product required by mlx-swift-lm) → **ALIVE APPLE**

### 3. Confirm packages are linked

1. Project navigator → select project **ALIVE APPLE** (blue icon).  
2. Select target **ALIVE APPLE**.  
3. Tab **General** → scroll to **Frameworks, Libraries, and Embedded Content**  
   **or** tab **Package Dependencies** (project level) + target **Build Phases → Link Binary With Libraries**.  
4. You should see MLXLLM / MLXLMCommon / MLXHuggingFace (and HuggingFace / Tokenizers).  
5. **Product → Clean Build Folder**, then **Build** (⌘B).

### 4. Verify real inference is compiled in

After a successful build with packages:

- `InferenceEngine.swift` compiles the `#if canImport(MLXLLM)` branches.  
- Loading a model with `.safetensors` uses `ModelContainer.load(directory:)`.  
- Chat uses `ChatSession` + `streamResponse` (with `respond` fallback).

If build fails on missing module names, re-open **Package Products** and enable any missing product Xcode lists for those repos.

### 5. Put models on the phone

App looks under **Documents/Models/`directoryName`/**:

| Model | Folder name | Hugging Face (MLX 4-bit) |
|-------|-------------|---------------------------|
| **Phi-4 Mini** (chat) | `phi-4-mini` | `mlx-community/Phi-4-mini-instruct-4bit` |
| SmolVLM2 (vision) | `smolvlm2` | `mlx-community/SmolVLM2-2.2B-Instruct-4bit` |

1. Download the HF folder (or copy from USB) so it contains **`.safetensors`** + **`config.json`**.  
2. On device: **Models** tab → Browse / USB import into that directory name.  
3. **Load Phi-4 Mini** → open **Chat** → send a message.

---

## Optional: XcodeGen `project.yml` (advanced)

You can also declare packages in `project.yml` and re-run `xcodegen generate`.  
If you do that, **CI will also try to resolve MLX** (slower; needs network).  
Until then, **UI-added packages only on your Mac** keep GitHub Actions on the demo path.

---

## Troubleshooting

| Symptom | What to do |
|---------|------------|
| Still see “Demo mode” in replies | Packages not linked to **ALIVE APPLE** target, or clean rebuild |
| `modelFileNotFound` | Folder name must match `directoryName`; need `.safetensors` |
| Package resolve fails | Use branch `main`, or update Xcode; check network / VPN |
| Out of memory on device | Unload vision before text; use 4-bit Phi-4 Mini only first |
