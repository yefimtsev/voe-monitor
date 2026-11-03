#!/usr/bin/env bash
# Write the App Store Connect API key from $ASC_KEY_CONTENT to the file given as $1, as PKCS#8 PEM.
# Accepts the .p8 itself or base64 of it (up to three layers), with copy-paste line breaks, spaces,
# CRLF or literal "\n", in PKCS#8 or SEC1 ("EC PRIVATE KEY") form.
# Never prints the key; on failure it prints only the PEM armor lines and the shape of what it decoded.
set -euo pipefail
export LC_ALL=C  # decoded garbage may be binary; keep tr and grep byte-oriented
out="$1"
umask 077
raw=$(mktemp)
trap 'rm -f "$raw"' EXIT

content="$ASC_KEY_CONTENT"
layers=0
while ! grep -q -- '-----BEGIN' <<<"$content" && [ -n "$content" ] && [ "$layers" -lt 3 ]; do
  content=$(printf '%s' "$content" | tr -d ' \t\r\n' | base64 --decode 2>/dev/null) || content=""
  layers=$((layers + 1))
done
printf '%s\n' "$content" | perl -pe 's/\\n/\n/g; s/\r//g' > "$raw"

# openssl both validates the key and rewrites it as the PKCS#8 PEM that asc and xcodebuild expect.
if openssl pkey -in "$raw" -out "$out" 2>/dev/null; then
  if [ "$layers" -gt 1 ]; then
    echo "::warning::ASC_KEY_CONTENT is base64-encoded $layers times. Setting it to the raw .p8 would be simpler."
  fi
  exit 0
fi

armor=$(grep -o -- '-----[A-Z ]*-----' "$raw" | tr '\n' ' ' || true)
echo "::error::ASC_KEY_CONTENT is not a usable private key. After $layers base64 layer(s): $(wc -c < "$raw" | tr -d ' ') bytes, $(wc -l < "$raw" | tr -d ' ') lines, PEM armor: ${armor:-none}"
exit 1
