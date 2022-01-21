#!/bin/bash
echo Download small databases for local execution
echo " ========================================== "
set -euxo pipefail 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST="$DIR"/../DB/

# Download human database
curl -L -o "$DEST"/kraken2_human_db.tar.gz "https://ndownloader.figshare.com/files/23567780"
tar xvfz "$DEST"/kraken2_human_db.tar.gz  -C "$DEST"/
# Small database
curl -o "$DEST"/k2_pluspf_8gb_20210517.tar.gz "https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_8gb_20210517.tar.gz"
mkdir -p "$DEST"/std8
tar xvfz "$DEST"/k2_pluspf_8gb_20210517.tar.gz -C "$DEST"/std8/

rm -f "$DEST"/k2_pluspf_8gb_20210517.tar.gz "$DEST"/kraken2_human_db.tar.gz