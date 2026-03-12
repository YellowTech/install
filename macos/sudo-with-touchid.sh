#!/bin/zsh

set -euo pipefail

PAM_FILE="/etc/pam.d/sudo"
TOUCH_ID_LINE="auth       sufficient     pam_tid.so"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This script only supports macOS." >&2
	exit 1
fi

if [[ ! -f "$PAM_FILE" ]]; then
	echo "Missing PAM configuration: $PAM_FILE" >&2
	exit 1
fi

if ! /usr/bin/grep -q "^[[:space:]]*auth[[:space:]]\+sufficient[[:space:]]\+pam_tid\.so$" "$PAM_FILE"; then
	temp_file="$(mktemp)"
	trap 'rm -f "$temp_file"' EXIT

	/usr/bin/awk -v touch_id_line="$TOUCH_ID_LINE" '
		NR == 1 {
			print
			print touch_id_line
			next
		}
		{ print }
	' "$PAM_FILE" > "$temp_file"

	/usr/bin/sudo /bin/cp "$PAM_FILE" "$PAM_FILE.bak.$(/bin/date +%Y%m%d%H%M%S)"
	/usr/bin/sudo /bin/cp "$temp_file" "$PAM_FILE"

	echo "Touch ID for sudo has been enabled."
	echo "A backup of $PAM_FILE was created next to the original file."
else
	echo "Touch ID for sudo is already enabled."
fi
