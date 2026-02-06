# video-understand

Understand any video file by combining audio transcription with visual frame analysis.

**Location:** `~/bin/video-understand`
**Script:** `/Users/ape/clawd/skills/video-understand/scripts/video-understand`

## Purpose

Simple, general-purpose video comprehension. Give it a video, get back what was said and what was shown.

## Usage

```bash
video-understand <video-file> [options]
```

### Options

- `--frames <n>` — Number of frames to extract (default: 8)
- `--transcript-only` — Only transcribe audio, skip visual analysis
- `--frames-only` — Only analyze frames, skip transcription
- `--output <file>` — Write output to file (default: stdout)
- `--json` — Output as JSON
- `--verbose` — Show progress

### Examples

```bash
# Basic understanding
video-understand clip.mp4

# More frames for longer videos
video-understand meeting.mov --frames 20

# Just the transcript
video-understand voicenote.mp4 --transcript-only

# JSON output for programmatic use
video-understand demo.mp4 --json
```

## Output

Default output is markdown:

```markdown
## Transcript
[What was said, with timestamps if available]

## Visual Summary
[What was shown in the video, frame by frame analysis synthesized]

## Summary
[Brief overall summary combining audio and visual]
```

## Requirements

- `ffmpeg` — Frame/audio extraction
- `whisper` or OpenAI Whisper API — Transcription
- Vision model access — Frame analysis (GPT-4V, Claude, etc.)

## How It Works

1. **Extract audio** → Temporary WAV file
2. **Transcribe** → Whisper (local or API)
3. **Extract frames** → Evenly spaced throughout video
4. **Analyze frames** → Vision model describes each
5. **Synthesize** → Combine transcript + visuals into coherent summary

## When to Use

- Screen recordings someone sent you
- Video messages / clips
- Quick "what's in this video?" queries
- Any video where you need to understand content without watching

## Limitations

- Long videos (>10min) may hit token limits — use `--frames` to sample appropriately
- Audio-only files work with `--transcript-only`
- Silent videos work with `--frames-only`
