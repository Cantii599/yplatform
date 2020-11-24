#!/usr/bin/env bash

function sf_rvm_unfuck() {
    # from https://github.com/matthew-brett/multibuild/blob/34b988aab60a93fa3c7bd1eb88dd7c4361ca464f/common_utils.sh#L17

    # Work round bug in travis xcode image described at
    # https://github.com/direnv/direnv/issues/210
    shell_session_update() { :; }

    # Workaround for https://github.com/travis-ci/travis-ci/issues/8703
    # suggested by Thomas K at
    # https://github.com/travis-ci/travis-ci/issues/8703#issuecomment-347881274
    unset -f cd
    unset -f pushd
    unset -f popd
}
sf_rvm_unfuck


# github action checkout
function sf_ga_checkout() {
    cd ${GITHUB_WORKSPACE}
    GIT_BRANCH=
    GIT_CLONE_BRANCH_ARG=
    if [[ "${GITHUB_REF:-}" =~ "^refs/heads/" ]]; then
        GIT_BRANCH=${GITHUB_REF#refs\/heads\/}
        GIT_CLONE_BRANCH_ARG="--branch=${GIT_BRANCH}"
    fi
    git clone --depth=50 ${GIT_CLONE_BRANCH_ARG} git@github.com:${GITHUB_REPOSITORY}.git
    cd $(basename ${GITHUB_REPOSITORY})
    [[ -z "${GIT_BRANCH}" ]] || {
        git checkout -B ${GIT_BRANCH}
    }
    git reset --hard ${GITHUB_SHA}
    git submodule update --init --recursive
}


function sf_github_https() {
    SF_GITHUB_TOKEN=${SF_GITHUB_TOKEN:-${GH_TOKEN:-}}
    [[ -n "${SF_GITHUB_TOKEN:-}" ]] || return 0

    echo_do "Found SF_GITHUB_TOKEN, setting up github.com HTTPS authentication..."
    echo -e "machine github.com\n  login ${SF_GITHUB_TOKEN}" >> ${HOME}/.netrc

    # cover git submodules's canonical ssh url
    git config --global --replace-all url.https://github.com/.insteadOf git@github.com:
    # cover npm package.json's canonical git+ssh url
    git config --global --add url.https://github.com/.insteadOf ssh://git@github.com/
    echo_done
}


function sf_transcrypt() {
    # de-transcrypt only for non-PRs or for PRs from the same repo
    [[ "${CI_IS_PR:-}" != "true" ]] || {
        [[ "${CI_PR_SLUG}" = "${CI_REPO_SLUG}" ]] || return 0
    }
    [[ -x "./transcrypt" ]] || return 0
    [[ -n "${TRANSCRYPT_PASSWORD:-}" ]] || return 0

    if git config --local transcrypted.version >/dev/null; then
        echo_skip "${FUNCNAME[0]}: Repository isn't transcrypted..."
        return 0
    fi

    echo_do "Found TRANSCRYPT_PASSWORD, setting up transcrypt..."
    ./transcrypt -y -c "${TRANSCRYPT_CIPHER:-aes-256-cbc}" -p "${TRANSCRYPT_PASSWORD}"
    unset TRANSCRYPT_CIPHER
    unset TRANSCRYPT_PASSWORD
    echo_done
}


function sf_os_get_dir_owner() {
    local GNU_STAT=$(stat --version 2>/dev/null | head -1 | grep -q "GNU" && echo true || echo false)
    case ${GNU_STAT} in
        true)
            local STAT_FORMAT_ARG="-c"
            local STAT_FORMAT_USER="%U"
            ;;
        false) # assume BSD
            local STAT_FORMAT_ARG="-f"
            local STAT_FORMAT_USER="%Su"
            ;;
    esac

    stat ${STAT_FORMAT_ARG} ${STAT_FORMAT_USER} $1
}

function sf_os_bootstrap_with_script() {
    BOOTSTRAP_SCRIPT=$1

    # recursive chown is slow in Docker, but linuxbrew requires the invoking user to own the linuxbrew folders
    # so the bootstrap script (which invokes linuxbrew) needs to run as the same user that is owning the folders
    # see https://github.com/docker/for-linux/issues/388
    local BOOTSTRAP_SCRIPT_USER=$(id -u -n)
    if which brew >/dev/null 2>&1; then
        BOOTSTRAP_SCRIPT_USER=$(sf_os_get_dir_owner $(brew --prefix)/Homebrew)
    elif test -x /home/linuxbrew/.linuxbrew/bin/brew; then
        BOOTSTRAP_SCRIPT_USER=$(sf_os_get_dir_owner $(/home/linuxbrew/.linuxbrew/bin/brew --prefix)/Homebrew)
    elif test -x ${HOME}/.linuxbrew/bin/brew; then
        BOOTSTRAP_SCRIPT_USER=$(sf_os_get_dir_owner $(${HOME}/.linuxbrew/bin/brew --prefix)/Homebrew)
    fi

    if [[ "$(id -u -n)" = "${BOOTSTRAP_SCRIPT_USER}" ]]; then
        echo_info "Running ${BOOTSTRAP_SCRIPT} as current user $(id -u -n)."
        ${BOOTSTRAP_SCRIPT}
    else
        echo_info "Running ${BOOTSTRAP_SCRIPT} as another user ${BOOTSTRAP_SCRIPT_USER}."
        sudo --preserve-env --set-home --user ${BOOTSTRAP_SCRIPT_USER} ${BOOTSTRAP_SCRIPT}
    fi
}


function sf_os() {
    [[ "${SF_FORCE_BOOTSTRAP:-}" = "true" ]] || {
        SF_GIT_HASH=$(git -C ${SUPPORT_FIRECLOUD_DIR} rev-parse HEAD)
        [[ ! -f /support-firecloud.bootstrapped ]] || {
            SF_GIT_HASH_BOOTSTRAPPED=$(cat /support-firecloud.bootstrapped)
            echo_info "${FUNCNAME[0]}: /support-firecloud.bootstrapped exists."
            echo_info "${FUNCNAME[0]}: /support-firecloud.bootstrapped references ${SF_GIT_HASH_BOOTSTRAPPED}."
            echo_info "${FUNCNAME[0]}: ${SUPPORT_FIRECLOUD_DIR} references ${SF_GIT_HASH}."
            if [[ "${SF_GIT_HASH}" = "${SF_GIT_HASH_BOOTSTRAPPED}" ]]; then
                echo_info "${FUNCNAME[0]}: Match found. Bootstrapping without minimal/common dependencies."
                echo_info "${FUNCNAME[0]}: Running with SF_SKIP_COMMON_BOOTSTRAP=true."
                export SF_SKIP_COMMON_BOOTSTRAP=true
                export SF_LOG_BOOTSTRAP=true
            else
                echo_info "${FUNCNAME[0]}: Match not found. Bootstrapping from scratch."
            fi
        }
    }

    [[ "${CI_DEBUG_MODE:-}" != "true" ]] || {
        SF_LOG_BOOTSTRAP=${SF_LOG_BOOTSTRAP:-true}
    }
    echo_info "${FUNCNAME[0]}: Running with"
    echo_info "${FUNCNAME[0]}: SF_LOG_BOOTSTRAP=${SF_LOG_BOOTSTRAP:-}"
    echo_info "${FUNCNAME[0]}: SF_PRINTENV_BOOTSTRAP=${SF_PRINTENV_BOOTSTRAP:-}"

    local BOOTSTRAP_SCRIPT="${SUPPORT_FIRECLOUD_DIR}/bootstrap/${OS_SHORT}/bootstrap"

    if [[ "${SF_LOG_BOOTSTRAP:-}" = "true" ]]; then
        sf_os_bootstrap_with_script ${BOOTSTRAP_SCRIPT}
        return 0
    fi

    local TMP_SF_OS_LOG=$(mktemp)
    echo_info "${FUNCNAME[0]}: Redirecting into ${TMP_SF_OS_LOG} to minimize CI log..."

    echo " 0 1 2 3 4 5 6 7 8 9101112131415 min"
    while :;do echo -n " ."; /bin/sleep 60; done &
    local WHILE_LOOP_PID=$!
    trap "kill ${WHILE_LOOP_PID}" EXIT
    sf_os_bootstrap_with_script ${BOOTSTRAP_SCRIPT} >${TMP_SF_OS_LOG} 2>&1 || {
        hash -r
        echo
        echo_err "${FUNCNAME[0]}: Failed. The latest log tail follows:"
        tail -n1000 ${TMP_SF_OS_LOG}
        sleep 10 # see https://github.com/travis-ci/travis-ci/issues/6018
        return 1
    }
    hash -r
    echo
    kill ${WHILE_LOOP_PID} && trap " " EXIT
}


function sf_pyenv_init() {
    if which pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
    fi
}


function sf_ci_run_before_install() {
    sf_github_https
    sf_transcrypt
    sf_os
    sf_pyenv_init

    [[ "${CI_DEBUG_MODE:-}" != "true" ]] || {
        echo
        echo "  Please run \`./.ci.sh debug\` to activate your debug session !!!"
        echo
    }
}