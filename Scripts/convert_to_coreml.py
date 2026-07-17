#!/usr/bin/env python3
"""
ALIVE APPLE — CoreML Model Converter
Converts HuggingFace models to CoreML format for on-device inference.

Usage:
    python3 convert_to_coreml.py --model sentence-transformers/all-MiniLM-L6-v2 --output ./all-MiniLM-L6-v2.mlmodelc
    python3 convert_to_coreml.py --model openai/whisper-small --output ./whisper-small.mlmodelc

Requirements:
    pip install transformers coremltools torch
"""

import argparse
import os
import sys
from pathlib import Path

def check_dependencies():
    """Verify required packages are installed."""
    missing = []
    for pkg in ["transformers", "coremltools", "torch"]:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)
    
    if missing:
        print(f"Missing packages: {', '.join(missing)}")
        print(f"Install: pip install {' '.join(missing)}")
        sys.exit(1)

def convert_embedding_model(model_name: str, output_path: str):
    """Convert a sentence-transformers embedding model to CoreML."""
    import torch
    import coremltools as ct
    from transformers import AutoTokenizer, AutoModel
    
    print(f"\n{'='*60}")
    print(f"Converting: {model_name}")
    print(f"Output: {output_path}")
    print(f"{'='*60}\n")
    
    # Load model
    print("Loading model...")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModel.from_pretrained(model_name)
    model.eval()
    
    # Trace with example input
    print("Tracing model...")
    sample_text = "This is a sample sentence for tracing."
    inputs = tokenizer(sample_text, return_tensors="pt", padding=True, truncation=True, max_length=128)
    
    # Create wrapped model for tracing
    class EmbeddingModel(torch.nn.Module):
        def __init__(self, model):
            super().__init__()
            self.model = model
        
        def forward(self, input_ids, attention_mask):
            outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
            # Mean pooling
            token_embeddings = outputs.last_hidden_state
            attention_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
            sum_embeddings = torch.sum(token_embeddings * attention_mask_expanded, 1)
            sum_mask = torch.clamp(attention_mask_expanded.sum(1), min=1e-9)
            return sum_embeddings / sum_mask
    
    traced_model = torch.jit.trace(
        EmbeddingModel(model),
        (inputs["input_ids"], inputs["attention_mask"])
    )
    
    # Convert to CoreML
    print("Converting to CoreML...")
    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.TensorType(name="input_ids", shape=inputs["input_ids"].shape),
            ct.TensorType(name="attention_mask", shape=inputs["attention_mask"].shape),
        ],
        minimum_deployment_target=ct.target.iOS18,
        compute_units=ct.ComputeUnit.ALL,  # Use CPU + GPU + Neural Engine
    )
    
    # Save
    output_dir = str(Path(output_path).parent)
    os.makedirs(output_dir, exist_ok=True)
    mlmodel.save(output_path)
    
    print(f"\n✅ Model saved to: {output_path}")
    
    # Print info
    print(f"\nModel specs:")
    print(f"  Input: {mlmodel.get_spec().description.input}")
    print(f"  Output: {mlmodel.get_spec().description.output}")
    print(f"  Size: {os.path.getsize(output_path) / 1e6:.1f} MB")

def convert_smolvlm2_to_gguf(model_name: str, output_path: str):
    """Extract SmolVLM2 multimodal projector for llama.cpp VLM inference.
    ALIVE APPLE uses llama.cpp for VLM — requires both the GGUF LLM and
    a multimodal projector (.mmproj) loaded alongside it.
    
    Reference: llama.cpp/examples/llava for mmproj extraction procedure.
    """
    print(f"\n{'='*60}")
    print(f"SmolVLM2 → GGUF with mmproj: {model_name}")
    print(f"Output: {output_path}")
    print(f"{'='*60}\n")
    
    print("Manual steps (automated in full pipeline):")
    print("1. Install: pip install -r llama.cpp/requirements/requirements-convert.txt")
    print("2. Clone: git clone https://github.com/ggerganov/llama.cpp")
    print("3. Convert HF weights to GGUF:")
    print(f"   python llama.cpp/convert_hf_to_gguf.py {model_name} \\")
    print(f"       --outfile {output_path}")
    print("4. Extract multimodal projector:")
    print(f"   python -c \\")
    print(f"     'from convert_to_gguf import extract_mmproj;")
    print(f"      extract_mmproj(\"{model_name}\", \"{output_path}.mmproj\")'")
    print()
    print("The .gguf and .mmproj files must both be placed in the same")
    print("directory on the USB drive for ALIVE APPLE to load them.")


def convert_whisper_model(model_name: str, output_path: str):
    """Convert Whisper model to CoreML."""
    print(f"\n{'='*60}")
    print(f"Converting Whisper: {model_name}")
    print(f"Output: {output_path}")
    print(f"{'='*60}\n")
    
    print("⚠️  Full Whisper CoreML conversion requires additional setup.")
    print("   Recommended: Use Apple's whisper-cpp for on-device STT instead.")
    print("   See: https://github.com/ggerganov/whisper.cpp")
    print()
    print("   For CoreML conversion, use:")
    print("   https://github.com/apple/ml-whisper")
    
    # Placeholder — in production, use Apple's official whisper conversion
    output_dir = str(Path(output_path).parent)
    os.makedirs(output_dir, exist_ok=True)
    
    Path(output_path).touch()
    print(f"   Created placeholder at: {output_path}")

def main():
    parser = argparse.ArgumentParser(
        description="Convert HuggingFace models to CoreML for ALIVE APPLE"
    )
    parser.add_argument(
        "--model", "-m",
        required=True,
        help="HuggingFace model name (e.g., 'sentence-transformers/all-MiniLM-L6-v2')"
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Output path for the .mlmodelc file"
    )
    parser.add_argument(
        "--type", "-t",
        choices=["embedding", "whisper", "vlm-gguf"],
        default="embedding",
        help="Model type: embedding (CoreML), whisper (CoreML), vlm-gguf (mmproj)"
    )
    
    args = parser.parse_args()
    
    check_dependencies()
    
    if args.type == "embedding":
        convert_embedding_model(args.model, args.output)
    elif args.type == "whisper":
        convert_whisper_model(args.model, args.output)
    elif args.type == "vlm-gguf":
        convert_smolvlm2_to_gguf(args.model, args.output)

if __name__ == "__main__":
    main()
