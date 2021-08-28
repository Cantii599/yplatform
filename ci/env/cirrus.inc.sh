#!/usr/bin/env bash
# shellcheck disable=SC2034
true

function sf_ci_env_cirrus() {
    [[ "${CIRRUS_CI:-}" = "true" ]] || return 0

    [[ "${CIRRUS_REPO_CLONE_HOST:-}" = "github.com" ]]

    export CI=true
    CI_NAME="Cirrus CI"
    CI_PLATFORM=cirrus
    CI_SERVER_HOST=cirrus-ci.com
    CI_REPO_SLUG=${CIRRUS_REPO_FULL_NAME:-}
    CI_ROOT=${CIRRUS_WORKING_DIR:-}

    CI_IS_CRON=
    [[ -z "${CIRRUS_CRON:-}" ]] || CI_IS_CRON=true
    CI_IS_PR=
    [[ -z "${CIRRUS_PR:-}" ]] || CI_IS_PR=true


    CI_JOB_ID=${CIRRUS_TASK_ID:-}
    CI_PIPELINE_ID=${CIRRUS_BUILD_ID:-}
    CI_JOB_URL=https://cirrus-ci.com/task/${CI_JOB_ID}
    CI_PIPELINE_URL=https://cirrus-ci.com/build/${CI_PIPELINE_ID}

    CI_PR_URL=
    CI_PR_REPO_SLUG=
    CI_PR_GIT_HASH=
    CI_PR_GIT_BRANCH=
    [[ "${CI_IS_PR}" != "true" ]] || {
        CI_PR_URL=https://github.com/${CI_REPO_SLUG}/pull/${CIRRUS_PR:-}
        CI_PR_REPO_SLUG= # TODO
        CI_PR_GIT_HASH= # TODO
        CI_PR_GIT_BRANCH=${CIRRUS_BRANCH:-}
    }

    CI_GIT_HASH=${CIRRUS_CHANGE_IN_REPO:-}
    CI_GIT_BRANCH=${CIRRUS_BRANCH:-}
    [[ "${CI_IS_PR}" != "true" ]] || CI_GIT_BRANCH=${CIRRUS_BASE_BRANCH:-}
    CI_GIT_TAG=${CIRRUS_TAG:-}

    CI_DEBUG_MODE=${CI_DEBUG_MODE:-}
}

function sf_ci_printvars_cirrus() {
    printenv | grep \
        -e "^CI[=_]" \
        -e "^CIRRUS[=_]" \
        -e "^CONTINUOUS_INTEGRATION$" \
        -e "^GITHUB_CHECK_SUITE_ID$"
}

function sf_ci_known_env_() {
    # see https://cirrus-ci.org/guide/writing-tasks/#environment-variables
    cat <<EOF
CI
CIRRUS_CI
CI_NODE_INDEX
CI_NODE_TOTAL
CONTINUOUS_INTEGRATION
CIRRUS_API_CREATED
CIRRUS_BASE_BRANCH
CIRRUS_BASE_SHA
CIRRUS_BRANCH
CIRRUS_BUILD_ID
CIRRUS_CHANGE_IN_REPO
CIRRUS_CHANGE_MESSAGE
CIRRUS_CHANGE_TITLE
CIRRUS_CRON
CIRRUS_DEFAULT_BRANCH
CIRRUS_LAST_GREEN_BUILD_ID
CIRRUS_LAST_GREEN_CHANGE
CIRRUS_PR
CIRRUS_PR_DRAFT
CIRRUS_TAG
CIRRUS_OS
CIRRUS_TASK_NAME
CIRRUS_TASK_ID
CIRRUS_RELEASE
CIRRUS_REPO_CLONE_TOKEN
CIRRUS_REPO_NAME
CIRRUS_REPO_OWNER
CIRRUS_REPO_FULL_NAME
CIRRUS_REPO_CLONE_URL
CIRRUS_USER_COLLABORATOR
CIRRUS_USER_PERMISSION
CIRRUS_HTTP_CACHE_HOST
GITHUB_CHECK_SUITE_ID
CIRRUS_ENV
CIRRUS_CLONE_DEPTH
CIRRUS_CLONE_SUBMODULES
CIRRUS_LOG_TIMESTAMP
CIRRUS_SHELL
CIRRUS_VOLUME
CIRRUS_WORKING_DIR
EOF
    # undocumented but observed
    cat <<EOF
CIRRUS_ARCH
CIRRUS_COMMIT_MESSAGE
CIRRUS_CPU
CIRRUS_REPO_CLONE_HOST
CIRRUS_REPO_ID
EOF
}
