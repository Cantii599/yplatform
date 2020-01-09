#!/usr/bin/env bash

# SUPPORT_FIRECLOUD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/support-firecloud" && pwd)"
SUPPORT_FIRECLOUD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source ${SUPPORT_FIRECLOUD_DIR}/sh/common.inc.sh

function ci_run_before_install() {
    [[ ${OS_SHORT} != "linux" ]] || {
        apt-get update
        apt-get install -y git
    }

    sf_ci_run_before_install
}

function ci_run_before_deploy() {
    true
}

function ci_run_deploy_docker_image() {
    DOCKER_ORG=${DOCKER_ORG:-tobiipro}
    [[ -n "${DOCKER_USERNAME:-}" ]] || return
    [[ -n "${DOCKER_PASSWORD:-}" ]] || return
    [[ -e "/etc/os-release" ]] || return

    RELEASE_ID="$(source /etc/os-release && echo ${ID})"
    RELEASE_VERSION_CODENAME="$(source /etc/os-release && echo ${VERSION_CODENAME})"
    DOCKER_IMAGE_NAME=sf-${RELEASE_ID}-${RELEASE_VERSION_CODENAME}-${SF_CI_BREW_INSTALL}
    DOCKER_IMAGE_TAG=${GIT_HASH_SHORT}
    DOCKERFILE=${SUPPORT_FIRECLOUD_DIR}/ci/${OS_SHORT}/Dockerfile.${RELEASE_ID}.${RELEASE_VERSION_CODENAME}
    [[ -f "${DOCKERFILE}" ]] || return

    # NOTE jq must be preinstalled
    TIMESTAMP_LATEST=$(
        curl https://hub.docker.com/v2/repositories/${DOCKER_ORG}/${DOCKER_IMAGE_NAME}/tags/latest | \
            jq -r .last_updated | \
            xargs -0 date +%s -d || \
            echo 0)

    echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

    docker build . \
        --file ${DOCKERFILE} \
        --tag ${DOCKER_ORG}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
        --build-arg IMAGE_TAG=${DOCKER_IMAGE_TAG} \
        --build-arg SF_CI_BREW_INSTALL=${SF_CI_BREW_INSTALL}

    docker push ${DOCKER_ORG}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}

    if [[ $(git show -s --format=%ct HEAD) -ge ${TIMESTAMP_LATEST} ]]; then
        docker tag ${DOCKER_ORG}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_ORG}/${DOCKER_IMAGE_NAME}:latest
        docker push ${DOCKER_ORG}/${DOCKER_IMAGE_NAME}:latest
    fi
}

function ci_run_deploy() {
    [[ -z "${SF_DEPLOY_DOCKER_IMAGE:-}" ]] || ci_run_deploy_docker_image
}

source "${SUPPORT_FIRECLOUD_DIR}/repo/dot.ci.sh.sf"
