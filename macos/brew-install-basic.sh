#!/bin/zsh

set -euo pipefail

BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
ZPROFILE_FILE="$HOME/.zprofile"
ZSHRC_FILE="$HOME/.zshrc"
MANAGED_BLOCK_START="# >>> install/brew-install-basic.sh >>>"
MANAGED_BLOCK_END="# <<< install/brew-install-basic.sh <<<"

find_brew_bin() {
	if command -v brew >/dev/null 2>&1; then
		command -v brew
		return 0
	fi

	for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [[ -x "$candidate" ]]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done

	return 1
}

ensure_brew_shellenv_in_file() {
	local brew_bin="$1"
	local target_file="$2"

	touch "$target_file"

	MANAGED_BLOCK_START="$MANAGED_BLOCK_START" MANAGED_BLOCK_END="$MANAGED_BLOCK_END" BREW_BIN="$brew_bin" \
		/usr/bin/perl -0pi -e '
			my $start = quotemeta($ENV{MANAGED_BLOCK_START});
			my $end = quotemeta($ENV{MANAGED_BLOCK_END});
			my $brew_bin = $ENV{BREW_BIN};
			my $block = "$ENV{MANAGED_BLOCK_START}\neval \"\\$($brew_bin shellenv)\"\n$ENV{MANAGED_BLOCK_END}\n";
			s/\n?$start\n.*?\n$end\n?//smg;
			$_ .= "\n" unless /\n\z/ || $_ eq q{};
			$_ .= $block;
		' "$target_file"
}

ensure_homebrew() {
	local brew_bin

	if brew_bin="$(find_brew_bin)"; then
		eval "$($brew_bin shellenv)"
		ensure_brew_shellenv_in_file "$brew_bin" "$ZPROFILE_FILE"
		ensure_brew_shellenv_in_file "$brew_bin" "$ZSHRC_FILE"
		return
	fi

	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL "$BREW_INSTALL_URL")"

	brew_bin="$(find_brew_bin)" || {
		echo "Homebrew installation failed." >&2
		exit 1
	}

	eval "$($brew_bin shellenv)"
	ensure_brew_shellenv_in_file "$brew_bin" "$ZPROFILE_FILE"
	ensure_brew_shellenv_in_file "$brew_bin" "$ZSHRC_FILE"
}

main() {
	ensure_homebrew
	brew install htop git git-lfs
	brew install --cask iterm2
}

main "$@"
