import os
import glob
import whisper
from pyannote.audio import Pipeline
from pydub import AudioSegment
import subprocess

# === CONFIG ===
AUDIO_DIR = r"E:\Education\Saxion\Internship\Audio\173"
OUTPUT_DIR = os.path.join(AUDIO_DIR, "output")
HUGGINGFACE_TOKEN = "YOUR_HUGGINGFACE_TOKEN_HERE"  # <-- Replace with your token

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"

# === Convert all part_*.m4a to part_*.wav ===
print("Converting .m4a files to .wav...")
for m4a_file in sorted(glob.glob(os.path.join(AUDIO_DIR, "part_*.m4a"))):
    wav_file = m4a_file.rsplit(".", 1)[0] + ".wav"
    if not os.path.exists(wav_file):
        subprocess.run(["ffmpeg", "-y", "-i", m4a_file, wav_file])
        print(f"Converted: {m4a_file} -> {wav_file}")

# === Load Models ===
print("\nLoading models...")
pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization", use_auth_token=HUGGINGFACE_TOKEN)
whisper_model = whisper.load_model("tiny")  # Or "base", etc.

# === Process Each Audio File ===
conversation = []
wav_files = sorted(glob.glob(os.path.join(AUDIO_DIR, "part_*.wav")))
if not wav_files:
    print("❌ No .wav parts found!")
    exit(1)

for audio_file in wav_files:
    print(f"\nProcessing {audio_file}...")
    diarization = pipeline(audio_file)
    audio = AudioSegment.from_file(audio_file)

    for i, (segment, _, speaker) in enumerate(diarization.itertracks(yield_label=True)):
        start_ms = int(segment.start * 1000)
        end_ms = int(segment.end * 1000)

        segment_audio = audio[start_ms:end_ms]
        temp_path = os.path.join(OUTPUT_DIR, f"temp_{i}.wav")
        segment_audio.export(temp_path, format="wav")

        result = whisper_model.transcribe(temp_path)
        text = result['text'].strip()
        conversation.append(f"{speaker}: {text}")

        os.remove(temp_path)

# === Save Conversation ===
output_path = os.path.join(OUTPUT_DIR, "full_conversation.txt")
with open(output_path, "w", encoding="utf-8") as f:
    for line in conversation:
        f.write(line + "\n")

print(f"\n✅ Conversation saved at {output_path}")