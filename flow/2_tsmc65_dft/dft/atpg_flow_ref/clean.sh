#!/bin/bash
set -uo pipefail

cd "$(dirname "$0")"

echo ">> Cleaning: $(pwd)"

rm -rf out_data/ *.log *.prj

echo ">> Done!"
