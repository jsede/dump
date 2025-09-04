#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <SRR12345678> [outdir]" >&2
  exit 1
fi

SRR="$1"
OUTDIR="${2:-.}"

curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${SRR}&result=read_run&fields=fastq_ftp&format=tsv" \
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
