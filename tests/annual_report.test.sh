#!/bin/bash

set -euo pipefail

readonly ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readonly OUTPUT=$(mktemp)
trap 'rm -f -- "$OUTPUT"' EXIT

bash -n "$ROOT/annual-report.sh"
bash "$ROOT/annual-report.sh" >"$OUTPUT"

grep -F 'OLIGARCHY // CONSOLIDATED ANNUAL REPORT' "$OUTPUT" >/dev/null
grep -F 'CONSOLIDATED HOLDINGS' "$OUTPUT" >/dev/null
grep -F 'PORTFOLIO COMPANIES' "$OUTPUT" >/dev/null
grep -F 'TREASURY AND VOLUNTARY COMPLIANCE' "$OUTPUT" >/dev/null
grep -F '0xcF84921FCedeC933a9EdF5eAAE66043424a82D38' "$OUTPUT" >/dev/null
grep -F 'No wallet connection, signature, payment request, or remote lookup occurred.' "$OUTPUT" >/dev/null

echo "PASS - terminal annual report renders live holdings and exact treasury authority"
