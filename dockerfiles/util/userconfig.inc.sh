#!/usr/bin/env bash
set -euo pipefail

[[ -e ${UHOME}/.bashrc ]] || cat <<EOF >> ${UHOME}/.bashrc
# If not running interactively, don't do anything
[[ $- = *i* ]] || return
EOF
cat ${UHOME}/.bashrc | grep -q "/\.bash_aliases" || cat <<EOF >> ${UHOME}/.bashrc
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
[[ ! -f ~/.bash_aliases ]] || . ~/.bash_aliases
EOF
chown ${UID_INDEX}:${GID_INDEX} ${UHOME}/.bashrc

cat <<EOF >> ${UHOME}/.bash_aliases
# poor-man version of sh/exe.inc.sh:sh_shellopts
OPTS_STATE="\$(set +o); \$(shopt -p)"
source ${YP_DIR}/bootstrap/brew-util/env.inc.sh
source ${YP_DIR}/sh/dev.inc.sh
# revert any shell options set in the scripts above
eval "\${OPTS_STATE}"; unset OPTS_STATE
EOF
chown ${UID_INDEX}:${GID_INDEX} ${UHOME}/.bash_aliases

mkdir -p ${UHOME}/.ssh
chmod 700 ${UHOME}/.ssh
chown ${UID_INDEX}:${GID_INDEX} ${UHOME}/.ssh

ln -sf /yplatform/sshconfig ${UHOME}/.ssh/yplatform
chown ${UID_INDEX}:${GID_INDEX} ${UHOME}/.ssh/yplatform

cat <<EOF > ${UHOME}/.ssh/config
Include ~/.ssh/yplatform/config
EOF
chmod 600 ${UHOME}/.ssh/config
chown ${UID_INDEX}:${GID_INDEX} ${UHOME}/.ssh/config

touch ${UHOME}/.sudo_as_admin_successful
chown ${UID_INDEX}:${GID_INDEX} ${UHOME}/.sudo_as_admin_successful
