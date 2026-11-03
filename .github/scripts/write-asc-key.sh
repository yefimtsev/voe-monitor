#!/usr/bin/env bash
# Write the App Store Connect API key from $ASC_KEY_CONTENT to the file given as $1.
# Accepts the .p8 itself or base64 of it, with whatever line breaks or spaces a copy-paste added.
# Never prints the key; on failure it says what the decoded content looks like.
set -euo pipefail
out="$1"
umask 077

if grep -q -- '-----BEGIN' <<<"$ASC_KEY_CONTENT"; then
  printf '%s\n' "$ASC_KEY_CONTENT" | tr -d '\r' > "$out"
else
  printf '%s' "$ASC_KEY_CONTENT" | tr -d ' \t\r\n' | base64 --decode > "$out" || true
fi

if grep -q -- '-----BEGIN PRIVATE KEY-----' "$out" && openssl pkey -in "$out" -noout 2>/dev/null; then
  exit 0
fi

size=$(wc -c < "$out" | tr -d ' ')
if head -c 64 "$out" | grep -Eq '^[A-Za-z0-9+/=]+$'; then
  shape="the decoded text is base64 again (secret was encoded twice?)"
elif [ "$size" -eq 0 ]; then
  shape="nothing decoded (empty secret or not base64)"
else
  shape="$size bytes that are not a PEM private key"
fi
echo "::error::ASC_KEY_CONTENT is not a .p8 key or base64 of one: $shape"
exit 1
