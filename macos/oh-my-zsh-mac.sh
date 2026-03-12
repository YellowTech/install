#!/bin/zsh

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || {
	echo "This script only supports macOS." >&2
	exit 1
}

for command_name in brew curl git; do
	command -v "$command_name" >/dev/null 2>&1 || {
		echo "$command_name is required but is not installed." >&2
		[[ "$command_name" == "brew" ]] && echo "Install it from https://brew.sh and run this script again." >&2
		exit 1
	}
done

ZSH_DIR="$HOME/.oh-my-zsh"
ZSHRC_FILE="$HOME/.zshrc"
OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
AUTOSUGGESTIONS_FORMULA="zsh-autosuggestions"
SYNTAX_HIGHLIGHTING_FORMULA="zsh-syntax-highlighting"
FONT_CASK="font-hack-nerd-font"
MANAGED_BLOCK_START="# >>> install/oh-my-zsh.sh >>>"
MANAGED_BLOCK_END="# <<< install/oh-my-zsh.sh <<<"

remove_managed_block() {
	MANAGED_BLOCK_START="$MANAGED_BLOCK_START" MANAGED_BLOCK_END="$MANAGED_BLOCK_END" \
		/usr/bin/perl -0pi -e '
			my $start = quotemeta($ENV{MANAGED_BLOCK_START});
			my $end = quotemeta($ENV{MANAGED_BLOCK_END});
			s/\n?$start\n.*?\n$end\n?//smg;
		' "$ZSHRC_FILE"
}

ensure_single_oh_my_zsh_source() {
	SOURCE_LINE='source $ZSH/oh-my-zsh.sh' \
		/usr/bin/perl -0pi -e '
			my $source = $ENV{SOURCE_LINE};
			my $seen = 0;
			my @lines = split /\n/, $_, -1;
			$_ = join "\n", grep { $_ ne $source || !$seen++ } @lines;
		' "$ZSHRC_FILE"
}

install_formula() {
	local formula="$1"

	if brew list "$formula" >/dev/null 2>&1; then
		echo "$formula is already installed."
		return
	fi

	echo "Installing $formula..."
	brew install "$formula"
}

install_oh_my_zsh() {
	if [[ -d "$ZSH_DIR" ]]; then
		echo "Oh My Zsh is already installed."
		return
	fi

	echo "Installing Oh My Zsh..."
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OMZ_INSTALL_URL")"
}

ensure_zshrc_exists() {
	[[ -f "$ZSHRC_FILE" ]] && return

	if [[ -f "$ZSH_DIR/templates/zshrc.zsh-template" ]]; then
		cp "$ZSH_DIR/templates/zshrc.zsh-template" "$ZSHRC_FILE"
		return
	fi

	cat > "$ZSHRC_FILE" <<EOF
export ZSH="$ZSH_DIR"
ZSH_THEME="agnoster"
plugins=(git)

source \$ZSH/oh-my-zsh.sh
EOF
}

set_or_append_setting() {
	local key="$1"
	local value="$2"

	SETTING_KEY="$key" SETTING_VALUE="$value" \
		/usr/bin/perl -0pi -e '
			my $key = $ENV{SETTING_KEY};
			my $value = $ENV{SETTING_VALUE};
			my $pattern = quotemeta($key);
			if (!s/^$pattern=.*$/$key=$value/m) {
				$_ .= "\n" unless /\n\z/;
				$_ .= "$key=$value\n";
			}
		' "$ZSHRC_FILE"
}

configure_zshrc() {
	ensure_zshrc_exists

	set_or_append_setting "export ZSH" '"'"$ZSH_DIR"'"'
	set_or_append_setting "ZSH_THEME" '"agnoster"'
	set_or_append_setting "plugins" '(git)'

	remove_managed_block
	ensure_single_oh_my_zsh_source

	cat >> "$ZSHRC_FILE" <<EOF

$MANAGED_BLOCK_START
source \$(brew --prefix $AUTOSUGGESTIONS_FORMULA)/share/$AUTOSUGGESTIONS_FORMULA/$AUTOSUGGESTIONS_FORMULA.zsh
source \$(brew --prefix $SYNTAX_HIGHLIGHTING_FORMULA)/share/$SYNTAX_HIGHLIGHTING_FORMULA/$SYNTAX_HIGHLIGHTING_FORMULA.zsh
$MANAGED_BLOCK_END
EOF
}

install_plugins() {
	install_formula "$AUTOSUGGESTIONS_FORMULA"
	install_formula "$SYNTAX_HIGHLIGHTING_FORMULA"
}

install_hack_font() {
	if brew list --cask "$FONT_CASK" >/dev/null 2>&1; then
		echo "Hack Nerd Font is already installed."
		return
	fi

	echo "Installing Hack Nerd Font..."
	brew install --cask "$FONT_CASK"
}

main() {
	install_oh_my_zsh
	install_plugins
	configure_zshrc
	install_hack_font

	echo "Oh My Zsh configuration is complete."
	echo "Restart your shell or run: source ~/.zshrc"
}

main "$@"
