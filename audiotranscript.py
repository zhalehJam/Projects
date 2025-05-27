import whisper
import torch
import os
import glob

model = whisper.load_model("tiny")
print("CUDA available:", torch.cuda.is_available())

files = sorted(glob.glob(r"E:\Education\Saxion\Internship\Audio\170\part_*.m4a"))

full_text = ""

for f in files:
    print(f"Transcribing: {f}")
    result = model.transcribe(f)
    full_text += result["text"] + "\n"

# Save transcript
output_path = r"E:\Education\Saxion\Internship\Audio\170\170_transcription_output.txt"
with open(output_path, "w", encoding="utf-8") as f:
    f.write(full_text)

print(f"\n✅ Transcription saved to: {output_path}")