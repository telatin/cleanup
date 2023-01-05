#!/bin/bash
echo Download Cleanup custom databases
echo " ========================================== "
set -euxo pipefail 
DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DEST="$DIR"/../../databases/
mkdir -p "$DEST"

# Download cleanup
curl -L -o "$DEST"/cleanup-db.zip "https://zenodo.org/record/7050266/files/cleanup-db.zip?download=1"
unzip "$DEST"/cleanup-db.zip -d "$DEST"/

curl -L -o "$DEST"/gutcheck-db.zip "https://zenodo.org/record/7050266/files/gutcheck-db.zip?download=1"
unzip "$DEST"/gutcheck-db.zip -d "$DEST"/
rm -f "$DEST"/cleanup-db.zip "$DEST"/gutcheck-db.zip
