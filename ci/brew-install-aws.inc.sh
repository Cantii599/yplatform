#!/usr/bin/env bash
set -euo pipefail

echo_do "brew: Installing AWS utils..."
BREW_FORMULAE="$(cat <<-EOF
https://raw.githubusercontent.com/Homebrew/linuxbrew-core/43884a240bb9ddf94d2b3f08d21963e30d3327b0/Formula/awscli.rb
EOF
)"
brew_install "${BREW_FORMULAE}"
unset BREW_FORMULAE
aws configure set s3.signature_version s3v4
echo_done

echo_do "brew: Testing AWS utils..."
# allow for a smooth transition to v2, but lock to version 2 by end of 2020
# exe_and_grep_q "aws --version | head -1" "^aws-cli/2\\."
exe_and_grep_q "aws --version | head -1" "^aws-cli/[12]\\."
echo_done
