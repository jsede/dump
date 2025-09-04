#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# ENA FASTQ downloader
# Prerequisite: aria2c must be installed.
#   Ubuntu/Debian: sudo apt-get install aria2
#   macOS (Homebrew): brew install aria2
#
# Copyright (c) 2025 John-Sebastian Eden & ChatGPT5
# -----------------------------------------------------------------------------

usage() {
    cat <<'EOF'
Usage: ena_fastq_get.sh [OPTIONS] <SRR_accession>

Download FASTQ files from ENA using aria2c.

Options:
  -h, --help           Show this help message and exit
  -o, --outdir DIR     Output directory (default: current directory)

Arguments:
  SRR_accession        Accession number (e.g., SRR12345678)

Prerequisites:
  Requires 'aria2c' (and also 'curl' and 'awk').

Examples:
  ena_fastq_get.sh SRR19790900
  ena_fastq_get.sh -o ./fastq SRR19790900
EOF
}

# ---- Parse options ----
OUTDIR="."
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -o|--outdir)
      if [[ $# -lt 2 ]]; then
        echo "Error: -o|--outdir requires a directory argument" >&2
        exit 1
      fi
      OUTDIR="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      echo
      usage
      exit 1
      ;;
    *)
      # First positional: SRR accession
      SRR="$1"
      shift
      # Allow no further positionals
      if [[ $# -gt 0 ]]; then
        echo "Error: unexpected extra arguments: $*" >&2
        echo
        usage
        exit 1
      fi
      break
      ;;
  esac
done

# ---- Validate inputs ----
if [[ -z "${SRR:-}" ]]; then
  echo "Error: SRR accession is required" >&2
  echo
  usage
  exit 1
fi

# Optional: light pattern check (doesn't block non-standard)
if ! [[ "$SRR" =~ ^SRR[0-9]+$ ]]; then
  echo "Warning: '$SRR' does not look like an SRR accession (SRR########). Continuing..." >&2
fi

# ---- Dependency checks ----
need() { command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' is required but not installed." >&2; exit 127; }; }
need curl
need awk
need aria2c

# ---- Prepare output ----
mkdir -p "$OUTDIR"

# ---- Fetch URLs from ENA and download with aria2c ----
echo "Fetching FASTQ URLs for ${SRR} from ENA..."
curl -fsS "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${SRR}&result=read_run&fields=fastq_ftp&format=tsv" \
| awk -F'\t' 'NR>1{
    n=split($2,a,";");
    for(i=1;i<=n;i++){
      u=a[i];
      if(u ~ /^ftp:\/\//) sub(/^ftp:\/\//,"https://",u);
      else if(u !~ /^https?:\/\//) u="https://" u;
      print u
    }
  }' \
| aria2c -x16 -s16 -j2 -c --retry-wait=5 --max-tries=0 --file-allocation=none -d "$OUTDIR" -i -

echo "Done. Files saved to: $OUTDIR"
