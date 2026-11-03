#!/usr/bin/env bash
# Write the App Store Connect API key from $ASC_KEY_CONTENT to the file given as $1.
# Accepts the .p8 itself or base64 of it, with whatever line breaks or spaces a copy-paste added.
# The secret this repo was set up with is base64-encoded twice (fastlane accepted that), so up to
# three layers are peeled. Never prints the key; on failure it says what the decoded content looks like.
set -euo pipefail
export LC_ALL=C  # decoded garbage may be binary; keep tr and grep byte-oriented
out="$1"
umask 077

content="$ASC_KEY_CONTENT"
layers=0
while ! grep -q -- '-----BEGIN' <<<"$content" && [ -n "$content" ] && [ "$layers" -lt 3 ]; do
  content=$(printf '%s' "$content" | tr -d ' \t\r\n' | base64 --decode 2>/dev/null) || content=""
  layers=$((layers + 1))
done
printf '%s\n' "$content" | tr -d '\r' > "$out"

if grep -q -- '-----BEGIN PRIVATE KEY-----' "$out" && openssl pkey -in "$out" -noout 2>/dev/null; then
  if [ "$layers" -gt 1 ]; then
    echo "::warning::ASC_KEY_CONTENT is base64-encoded $layers times. Setting it to the raw .p8 would be simpler."
  fi
  exit 0
fi

if [ -z "$content" ]; then
  shape="nothing decoded (empty secret or not base64)"
else
  shape="after $layers base64 layer(s), $(wc -c < "$out" | tr -d ' ') bytes that are not a PEM private key"
fi
echo "::error::ASC_KEY_CONTENT is not a .p8 key or base64 of one: $shape"
exit 1
