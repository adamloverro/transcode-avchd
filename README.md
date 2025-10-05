# AVCHD to MP4 Batch Transcoder

## Project Summary
This project provides a Bash script to batch transcode AVCHD `.MTS` video files to `.mp4` format using ffmpeg. The script supports batch conversion, single-file (chapter) conversion, and date-range-based conversion, with flexible quality presets and output naming that includes the original file's date and time.

## Prerequisites
- macOS or Linux (tested on macOS)
- [ffmpeg](https://ffmpeg.org/) and [ffprobe](https://ffmpeg.org/ffprobe.html) installed (install via Homebrew: `brew install ffmpeg`)
- Bash shell

## How to Use
1. Place your AVCHD folder structure in the project directory (default input: `./AVCHD/BDMV/STREAM`).
2. Make the script executable:
   ```sh
   chmod +x scripts/batch_transcode.sh
   ```
3. Run the script with your desired options (see below).

## Examples
### 1. Show Info Table
Print a table of all `.MTS` files, their dates, and durations:
```sh
./scripts/batch_transcode.sh info
```

### 2. Batch Transcode All Files
Transcode all `.MTS` files to MP4 (default quality: medium, output: `./output_mp4`):
```sh
./scripts/batch_transcode.sh
```

### 3. Batch Transcode to Custom Output and Quality
```sh
./scripts/batch_transcode.sh my_output_folder high
```

### 4. Transcode a Single Chapter (Nth File)
Transcode only the 5th `.MTS` file in high quality to `mp4-videos`:
```sh
./scripts/batch_transcode.sh chapter 5 mp4-videos high
```

### 5. Transcode by Date Range
Transcode only files created between Jan 1, 2008 and Dec 31, 2008 (inclusive), in high quality to `mp4-videos`:
```sh
./scripts/batch_transcode.sh start_date 20080101_000000 stop_date 20081231_235959 mp4-videos high
```

## Quality Presets
- `high`: CRF 18, preset slow (highest quality, largest file)
- `medium`: CRF 22, preset fast (default, good quality, smaller file)
- `low`: CRF 28, preset veryfast (lowest quality, smallest file)

## Output Naming
Output files are named as `<YYYYMMDD_HHMMSS>_<originalname>.mp4` based on the original file's modification date and time.

## Help
Run the script with `-h` or `--help` for usage instructions:
```sh
./scripts/batch_transcode.sh -h
```
