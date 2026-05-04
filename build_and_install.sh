#!/bin/bash
umask 0022 # so that the installed gem is readable by everyone
set -euo pipefail
install_dir="${HOME}/.gem"
bindir="${install_dir}/bin"
gem build akro.gemspec
gem install --install-dir "${install_dir}" --bindir "${bindir}" --no-document akro-0.0.9.gem
