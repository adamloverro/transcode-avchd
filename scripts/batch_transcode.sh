#!/bin/bash
# Batch transcode all .MTS files in AVCHD/BDMV/STREAM to MP4 format
# Usage: ./scripts/batch_transcode.sh [output_dir] [quality]
#        ./scripts/batch_transcode.sh info
#        ./scripts/batch_transcode.sh chapter N [output_dir] [quality]
#        ./scripts/batch_transcode.sh start_date YYYYMMDD_HHMMSS stop_date YYYYMMDD_HHMMSS [output_dir] [quality]

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 [output_dir] [quality]"
  echo "       $0 info"
  echo "       $0 chapter N [output_dir] [quality]"
  echo "       $0 start_date YYYYMMDD_HHMMSS stop_date YYYYMMDD_HHMMSS [output_dir] [quality]"
  echo "  output_dir: Directory to save MP4 files (default: ./output_mp4)"
  echo "  quality: One of high, medium, low (default: medium)"
  echo "    high   = CRF 18, preset slow (highest quality, largest file)"
  echo "    medium = CRF 22, preset fast (good quality, smaller file)"
  echo "    low    = CRF 28, preset veryfast (lowest quality, smallest file)"
  echo "  info: Print number of .MTS files, list them, and show video length for each."
  echo "  chapter N: Only transcode the Nth .MTS file (1-based index)."
  echo "  start_date/stop_date: Only transcode files with date/time between these (inclusive). Format: YYYYMMDD_HHMMSS."
  exit 0
fi

INPUT_DIR="./AVCHD/BDMV/STREAM"

if [[ "$1" == "info" ]]; then
  shopt -s nullglob
  mtsfiles=("$INPUT_DIR"/*.MTS)
  count=${#mtsfiles[@]}
  printf "Found %d .MTS files in %s:\n" "$count" "$INPUT_DIR"
  printf "%-5s %-20s %-20s %-10s\n" "#" "Filename" "Date" "Length(s)"
  printf "%-5s %-20s %-20s %-10s\n" "---" "--------------------" "--------------------" "----------"
  for i in "${!mtsfiles[@]}"; do
    file="${mtsfiles[$i]}"
    filedate=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$file")
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
    printf "%-5s %-20s %-20s %-10.2f\n" "$((i+1))" "$(basename -- "$file")" "$filedate" "$duration"
  done
  exit 0
fi

if [[ "$1" == "chapter" ]]; then
  CHAPTER_IDX=$2
  OUTPUT_DIR="${3:-./output_mp4}"
  QUALITY="${4:-medium}"
  shopt -s nullglob
  mtsfiles=("$INPUT_DIR"/*.MTS)
  count=${#mtsfiles[@]}
  if ! [[ "$CHAPTER_IDX" =~ ^[0-9]+$ ]] || (( CHAPTER_IDX < 1 || CHAPTER_IDX > count )); then
    echo "Invalid chapter number. There are $count chapters."
    exit 1
  fi
  file="${mtsfiles[$((CHAPTER_IDX-1))]}"
  filename=$(basename -- "$file" .MTS)
  filedate=$(stat -f '%Sm' -t '%Y%m%d_%H%M%S' "$file")
  outname="${filedate}_${filename}.mp4"
  case "$QUALITY" in
    high)
      CRF_VALUE=18
      PRESET=slow
      ;;
    medium)
      CRF_VALUE=22
      PRESET=fast
      ;;
    low)
      CRF_VALUE=28
      PRESET=veryfast
      ;;
    *)
      echo "Unknown quality preset: $QUALITY. Use high, medium, or low."
      exit 1
      ;;
  esac
  mkdir -p "$OUTPUT_DIR"
  echo "Transcoding chapter $CHAPTER_IDX: $file with quality=$QUALITY (CRF=$CRF_VALUE, preset=$PRESET). Output directory: $OUTPUT_DIR"
  ffmpeg -i "$file" -c:v libx264 -preset "$PRESET" -crf "$CRF_VALUE" -c:a aac -b:a 192k "$OUTPUT_DIR/$outname"
  echo "Transcoding complete. MP4 file is in $OUTPUT_DIR/$outname"
  exit 0
fi

if [[ "$1" == "start_date" ]]; then
  if [[ "$2" == "" || "$3" != "stop_date" || "$4" == "" ]]; then
    echo "Error: Usage is $0 start_date YYYYMMDD_HHMMSS stop_date YYYYMMDD_HHMMSS [output_dir] [quality]"
    exit 1
  fi
  START_DATE="$2"
  STOP_DATE="$4"
  OUTPUT_DIR="${5:-./output_mp4}"
  QUALITY="${6:-medium}"
  case "$QUALITY" in
    high)
      CRF_VALUE=18
      PRESET=slow
      ;;
    medium)
      CRF_VALUE=22
      PRESET=fast
      ;;
    low)
      CRF_VALUE=28
      PRESET=veryfast
      ;;
    *)
      echo "Unknown quality preset: $QUALITY. Use high, medium, or low."
      exit 1
      ;;
  esac
  mkdir -p "$OUTPUT_DIR"
  shopt -s nullglob
  mtsfiles=("$INPUT_DIR"/*.MTS)
  found=0
  for mtsfile in "${mtsfiles[@]}"; do
    filedate=$(stat -f '%Sm' -t '%Y%m%d_%H%M%S' "$mtsfile")
    if [[ "$filedate" < "$START_DATE" || "$filedate" > "$STOP_DATE" ]]; then
      continue
    fi
    found=1
    filename=$(basename -- "$mtsfile" .MTS)
    outname="${filedate}_${filename}.mp4"
    echo "Transcoding $mtsfile (date $filedate) with quality=$QUALITY (CRF=$CRF_VALUE, preset=$PRESET). Output directory: $OUTPUT_DIR"
    ffmpeg -i "$mtsfile" -c:v libx264 -preset "$PRESET" -crf "$CRF_VALUE" -c:a aac -b:a 192k "$OUTPUT_DIR/$outname"
  done
  if [[ $found -eq 0 ]]; then
    echo "No files found in date range $START_DATE to $STOP_DATE."
  else
    echo "Transcoding complete. MP4 files are in $OUTPUT_DIR"
  fi
  exit 0
fi

OUTPUT_DIR="${1:-./output_mp4}"
QUALITY="${2:-medium}"

case "$QUALITY" in
  high)
    CRF_VALUE=18
    PRESET=slow
    ;;
  medium)
    CRF_VALUE=22
    PRESET=fast
    ;;
  low)
    CRF_VALUE=28
    PRESET=veryfast
    ;;
  *)
    echo "Unknown quality preset: $QUALITY. Use high, medium, or low."
    exit 1
    ;;
esac

mkdir -p "$OUTPUT_DIR"

echo "Transcoding with quality=$QUALITY (CRF=$CRF_VALUE, preset=$PRESET). Output directory: $OUTPUT_DIR"

for mtsfile in "$INPUT_DIR"/*.MTS; do
  filename=$(basename -- "$mtsfile" .MTS)
  filedate=$(stat -f '%Sm' -t '%Y%m%d_%H%M%S' "$mtsfile")
  outname="${filedate}_${filename}.mp4"
  ffmpeg -i "$mtsfile" -c:v libx264 -preset "$PRESET" -crf "$CRF_VALUE" -c:a aac -b:a 192k "$OUTPUT_DIR/$outname"
done

echo "Batch transcoding complete. MP4 files are in $OUTPUT_DIR"
