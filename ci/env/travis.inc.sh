#!/usr/bin/env bash
# shellcheck disable=SC2034
true

function sf_ci_env_travis() {
    [[ "${TRAVIS:-}" = "true" ]] || return 0

    export CI=true
    CI_NAME="Travis CI"
    CI_PLATFORM=travis
    CI_SERVER_HOST=travis-ci.org
    CI_REPO_SLUG=${TRAVIS_REPO_SLUG:-}
    CI_ROOT=${TRAVIS_BUILD_DIR:-}

    CI_IS_CRON=false
    [[ "${TRAVIS_EVENT_TYPE}" != "cron" ]] || CI_IS_CRON=true
    CI_IS_PR=false
    [[ "${TRAVIS_EVENT_TYPE}" != "pull_request" ]] || CI_IS_PR=true

    CI_JOB_ID=${TRAVIS_JOB_ID:}
    CI_PIPELINE_ID=${TRAVIS_BUILD_NUMBER:-}
    CI_JOB_URL=${TRAVIS_JOB_WEB_URL:-}
    CI_PIPELINE_URL=${TRAVIS_BUILD_WEB_URL:-}

    CI_PR_URL=
    CI_PR_REPO_SLUG=
    CI_PR_GIT_HASH=
    CI_PR_GIT_BRANCH=
    [[ "${CI_IS_PR}" != "true" ]] || {
        CI_PR_URL=https://github.com/${CI_REPO_SLUG}/pull/${TRAVIS_PULL_REQUEST:-}
        CI_PR_REPO_SLUG=${TRAVIS_PULL_REQUEST_SLUG:-}
        CI_PR_GIT_HASH=${TRAVIS_PULL_REQUEST_SHA:-}
        CI_PR_GIT_BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-}
    }

    CI_GIT_HASH=${TRAVIS_COMMIT:-}
    CI_GIT_BRANCH=${TRAVIS_BRANCH:-}
    CI_GIT_TAG=${TRAVIS_TAG:-}

    CI_DEBUG_MODE=${TRAVIS_DEBUG_MODE:-}
}

function sf_ci_printvars_travis() {
    printenv | grep \
        -e "^CI[=_]" \
        -e "^CONTINUOUS_INTEGRATION$" \
        -e "^HAS_JOSH_K_SEAL_OF_APPROVAL$" \
        -e "^TRAVIS[=_]"
}

function sf_ci_known_env_travis() {
    # see https://docs-staging.travis-ci.com/user/environment-variables/#default-environment-variables
    cat <<EOF
CI
TRAVIS
CONTINUOUS_INTEGRATION
HAS_JOSH_K_SEAL_OF_APPROVAL
TRAVIS_ALLOW_FAILURE
TRAVIS_APP_HOST
TRAVIS_BRANCH
TRAVIS_BUILD_DIR
TRAVIS_BUILD_ID
TRAVIS_BUILD_NUMBER
TRAVIS_BUILD_WEB_URL
TRAVIS_COMMIT
TRAVIS_COMMIT_MESSAGE
TRAVIS_COMMIT_RANGE
TRAVIS_COMPILER
TRAVIS_DEBUG_MODE
TRAVIS_DIST
TRAVIS_EVENT_TYPE
TRAVIS_JOB_ID
TRAVIS_JOB_NAME
TRAVIS_JOB_NUMBER
TRAVIS_JOB_WEB_URL
TRAVIS_OS_NAME
TRAVIS_CPU_ARCH
TRAVIS_OSX_IMAGE
TRAVIS_PULL_REQUEST
TRAVIS_PULL_REQUEST_BRANCH
TRAVIS_PULL_REQUEST_SHA
TRAVIS_PULL_REQUEST_SLUG
TRAVIS_REPO_SLUG
TRAVIS_SECURE_ENV_VARS
TRAVIS_SUDO
TRAVIS_TEST_RESULT
TRAVIS_TAG
TRAVIS_BUILD_STAGE_NAME
TRAVIS_DART_VERSION
TRAVIS_GO_VERSION
TRAVIS_HAXE_VERSION
TRAVIS_JDK_VERSION
TRAVIS_JULIA_VERSION
TRAVIS_NODE_VERSION
TRAVIS_OTP_RELEASE
TRAVIS_PERL_VERSION
TRAVIS_PHP_VERSION
TRAVIS_PYTHON_VERSION
TRAVIS_R_VERSION
TRAVIS_RUBY_VERSION
TRAVIS_RUST_VERSION
TRAVIS_SCALA_VERSION
TRAVIS_MARIADB_VERSION
TRAVIS_XCODE_SDK
TRAVIS_XCODE_SCHEME
TRAVIS_XCODE_PROJECT
TRAVIS_XCODE_WORKSPACE
EOF
    # undocumented but observed
    cat <<EOF
EOF
}
