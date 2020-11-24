#!/usr/bin/env bash

# CIs have issues keeping stdout and stderr in sync because they parse the streams
# e.g. to mask secret values
exec 2>&1

SUPPORT_FIRECLOUD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source ${SUPPORT_FIRECLOUD_DIR}/sh/common.inc.sh

set -a
[[ ! -f ${GIT_ROOT}/CONST.inc ]] || source ${GIT_ROOT}/CONST.inc
if git config --local transcrypt.version >/dev/null; then
    [[ ! -f ${GIT_ROOT}/CONST.inc.secret ]] || source ${GIT_ROOT}/CONST.inc.secret
fi
set +a

source ${SUPPORT_FIRECLOUD_DIR}/ci/debug.inc.sh

source ${SUPPORT_FIRECLOUD_DIR}/ci/before-install.pre.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/ci/before-install.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/ci/install.inc.sh
# source ${SUPPORT_FIRECLOUD_DIR}/ci/before-script.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/ci/script.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/ci/before-cache.inc.sh
# source ${SUPPORT_FIRECLOUD_DIR}/ci/after-success.inc.sh
# source ${SUPPORT_FIRECLOUD_DIR}/ci/after-failure.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/ci/before-deploy.inc.sh
# source ${SUPPORT_FIRECLOUD_DIR}/ci/deploy.inc.sh
# source ${SUPPORT_FIRECLOUD_DIR}/ci/after-deploy.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/ci/after-script.inc.sh

source ${SUPPORT_FIRECLOUD_DIR}/ci/notifications.inc.sh


function sf_ci_run() {
    >&2 echo "$(date +"%H:%M:%S") [DO  ] $@"

    CMD=
    if [[ "$(type -t "ci_run_${1}")" = "function" ]]; then
        CMD="ci_run_${1}"
    elif [[ "$(type -t "sf_ci_run_${1}")" = "function" ]]; then
        CMD="sf_ci_run_${1}"
    else
        >&2 echo "$(date +"%H:%M:%S") [INFO] Couldn't find a ci_run_${1} or sf_ci_run_${1} function."

        >&2 echo "$(date +"%H:%M:%S") [DONE] $@"
        return 0
    fi

    if [[ "${TRAVIS:-}" != "true" ]]; then
        true
    elif [[ -f /support-firecloud.docker-ci ]]; then
        echo_info "Running inside the sf-docker-ci container."
    elif [[ "${OS_SHORT:-}" != "linux" ]]; then
        echo_info "Skipping the sf-docker-ci container because the host OS is not linux."
    elif ${SUPPORT_FIRECLOUD_DIR}/bin/is-wsl; then
        echo_info "Skipping the sf-docker-ci container because the host OS is Windows Subsystem for Linux."
    elif [[ "${SF_DOCKER_CI_IMAGE:-}" = "false" ]]; then
        echo_info "Skipping the sf-docker-ci container because SF_DOCKER_CI_IMAGE=false."
    else
        local RUN_IN_SF_DOCKER_CI="docker exec -it -w ${TRAVIS_BUILD_DIR} -u $(id -u):$(id -g) sf-docker-ci-travis"
        CMD="${RUN_IN_SF_DOCKER_CI} ${0} $@ 2>&1"
        # use unbuffer and pv to minimize risk of travis getting jammed due to log-processing quirks
        CMD="unbuffer ${CMD} | pv -q -L 3k"

        if [[ "${1}" = "before_install" ]]; then
            sf_run_docker_ci_in_travis

            # /home/travis is not readable by others, like the sf:sf user which will do the bootstrapping
            ${RUN_IN_SF_DOCKER_CI} sudo adduser sf travis
        fi
    fi

    if [[ "${1}" = "before_install" ]]; then
        if [[ ! -f /support-firecloud.docker-ci ]]; then
            sf_enable_travis_swap
        fi
    fi

    # print out the command before running it
    echo "$(pwd)\$ ${CMD}"

    eval "${CMD}"

    >&2 echo "$(date +"%H:%M:%S") [DONE] $@"
}

[[ "${TRAVIS:-}" != "true" ]] || source ${SUPPORT_FIRECLOUD_DIR}/ci/env.travis-ci.inc.sh
[[ "${CIRCLECI:-}" != "true" ]] || source ${SUPPORT_FIRECLOUD_DIR}/ci/env.circle-ci.inc.sh
[[ "${GITHUB_ACTIONS:-}" != "true" ]] || source ${SUPPORT_FIRECLOUD_DIR}/ci/env.github-actions.inc.sh
[[ "${CI_NAME:-}" != "codeship" ]] || source ${SUPPORT_FIRECLOUD_DIR}/ci/env.codeship.inc.sh
[[ "${GITLAB_CI:-}" != "true" ]] || source ${SUPPORT_FIRECLOUD_DIR}/ci/env.gitlab.inc.sh

[[ -z "$*" ]] || sf_ci_run $@