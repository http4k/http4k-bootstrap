#!/bin/bash

set -e
set -o errexit
set -o pipefail
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]:-.}" )" && pwd )"

GITHUB_USERNAME=${GITHUB_USERNAME:-}
GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN:-}
HEROKU_API_KEY=${HEROKU_API_KEY:-}

function ensure_command {
    COMMAND=$1
    command -v ${COMMAND} >/dev/null 2>&1 || { echo >&2 "$COMMAND is required. Aborting."; exit 1; }
}

function check_env {
    local missing_env=false
    if [[ -z "${GITHUB_USERNAME}" ]]; then
        echo "GITHUB_USERNAME is required"
        missing_env=true
    fi
    if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN}" ]]; then
        echo "GITHUB_PERSONAL_ACCESS_TOKEN is required (see https://github.com/settings/tokens)"
        missing_env=true
    fi
    if [[ -z "${HEROKU_API_KEY}" ]]; then
        echo "HEROKU_API_KEY is required (see https://dashboard.heroku.com/account#api-key)"
        missing_env=true
    fi
    if [[ "${missing_env}" == "true" ]]; then
        printf "\nPlease set the required environment variables and try again.\n"
        exit 1
    fi
}

function create_heroku_app {
    echo "Creating Heroku app..."
    local NAME=$1
    local RESPONSE="$(curl --silent -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -X POST --data "{\"name\":\"${NAME}\"}" https://api.heroku.com/apps \
        -H "Accept: application/vnd.heroku+json; version=3" \
        -H "Authorization: Bearer $HEROKU_API_KEY" \
        -H "Accept application/json")"
    local CREATED=$(echo ${RESPONSE} | jq '.created_at != null')
    
    if [[ "$CREATED" != "true" ]]; then
        echo "Could not create app '$NAME': $(echo ${RESPONSE} | jq .message)"
        exit -1
    fi
}

function create_github_repo {
    echo "Creating GitHub repository..."
	local NAME=$1
	local CREDENTIALS="$GITHUB_USERNAME:$GITHUB_PERSONAL_ACCESS_TOKEN"
	local STATUS=$(curl --silent -u ${CREDENTIALS} -H "Accept: application/vnd.github.v3+json" -H "Content-Type: application/json" -X POST --data "{\"name\": \"${NAME}\"}" https://api.github.com/user/repos)

    local HAS_ERRORS=$(echo ${STATUS} | jq '.errors | length == 0')
	if [ "${HAS_ERRORS}" == "false" ]; then
        local MESSAGE=$(echo ${STATUS} | jq '.errors[0].message')
	    echo "Failed to create repository '$NAME': $MESSAGE"
		exit -1
	fi
}

function retrieve_travis_token {
    local TRAVIS_ACCESS_TOKEN=$(curl --silent -H "User-Agent: Travis-http4k-boostrap/1.0" -H "Accept: application/vnd.travis-ci.2+echo json." -H "Content-Type: application/json" --data "{\"github_token\":\"${GITHUB_PERSONAL_ACCESS_TOKEN}\"}" https://api.travis-ci.org/auth/github | jq .access_token)
    if [[ -z "${TRAVIS_ACCESS_TOKEN}" ]]; then
        echo "Failed to obtain TravisCI token."
        exit -1
    fi
    echo ${TRAVIS_ACCESS_TOKEN}
}

function enable_travis {
    local NAME=$1
    local TOKEN=$(retrieve_travis_token)
    local REPO_PATH="${GITHUB_USERNAME}/${NAME}"
    local TRAVIS_REPO_ID=$(curl --silent -H "Authorization: token $TOKEN" -H "User-Agent: Travis-http4k-boostrap/1.0" -H "Content-Type: application/json"  "https://api.travis-ci.org/repos/${REPO_PATH}" | jq .id 2>/dev/null) #ignore errors as this call is likely to fail until repo becomes visible to travis
    if [[ -z "${TRAVIS_REPO_ID}" ]]; then
        echo "Failed to find TravisCI repo ID."
        return 1
    fi
    local RESULT=$(curl --silent -H "Authorization: token $TOKEN" -H "User-Agent: Travis-http4k-boostrap/1.0" -H "Content-Type: application/json"  -X PUT --data "{\"hook\":{\"id\": ${TRAVIS_REPO_ID},\"active\": true}}" "https://api.travis-ci.org/hooks" | jq .result 2>/dev/null)
    if [ "${RESULT}" != "true" ]; then
        echo "Failed to enable repo"
        return 1
    fi
    echo "TravisCI enabled for $REPO_PATH"
}

function enable_travis_for_repo { # Retry because github repo may take a bit of time to become visible to travis
   echo "Enabling TravisCI..."
   local n=0
   until [ ${n} -ge 5 ]; do
      result=$(enable_travis $1) && echo ${result} && break
      n=$[$n+1]
      sleep 10
   done
}

function update_travis_file {
    APP_NAME=$1
    TRAVIS_ACCESS_TOKEN=$(retrieve_travis_token)
    HEROKU_KEY=$(encrypt_heroku_key "$TRAVIS_ACCESS_TOKEN" "${GITHUB_USERNAME}/${APP_NAME}" "$HEROKU_API_KEY")
    if [[ -z "$HEROKU_KEY" ]]; then
        echo "Failed to encrypt Heroku API Key"
    fi
    cd "$DIR/$APP_NAME"
    sed -E -i '' "s@(.*secure: ).*@\1$HEROKU_KEY@g" .travis.yml
    sed -E -i '' "s@(.*app: ).*@\1$APP_NAME@g" .travis.yml
    git commit -am"Configure TravisCI"
    git push -u origin master
}

function encrypt_heroku_key {
    TOKEN=$1
    TRAVIS_REPO_ID=$2
    HEROKU_API_KEY=$3
    TEMP_FILE="$(mktemp)"
    KEY=$(curl --silent -H "Authorization: token $TOKEN" -H "User-Agent: Travis-http4k-boostrap/1.0" -H "Content-Type: application/json" "https://api.travis-ci.org/repos/${TRAVIS_REPO_ID}/key" | jq -r .key > ${TEMP_FILE})
    if [[ -z "$(cat ${TEMP_FILE})" ]]; then
        echo "Failed to retrieve TravisCI key."
        exit -1
    fi
    echo -n ${HEROKU_API_KEY} | openssl rsautl -encrypt -pubin -inkey ${TEMP_FILE} | base64
}

function clone_skeleton {
    local NAME=$1
    local REPO_DIR="${DIR}/$NAME"
    git clone "https://github.com/http4k/http4k-heroku-travis-example-app.git" "$REPO_DIR"
    cd ${REPO_DIR}
    git remote rm origin
    git remote add origin "git@github.com:${GITHUB_USERNAME}/${NAME}.git"
}

ensure_command "jq"
ensure_command "openssl"
check_env

APP_NAME=${1:-}

if [[ -z "${APP_NAME:-}" ]]; then
    echo "Usage: $0 <app-name>" >/dev/stderr
    exit 1
fi

printf "Setting up ${APP_NAME}\n\n"

create_heroku_app ${APP_NAME}
create_github_repo ${APP_NAME}
enable_travis_for_repo ${APP_NAME}
clone_skeleton ${APP_NAME}
update_travis_file ${APP_NAME}
