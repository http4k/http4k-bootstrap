set -e
set -o errexit
set -o pipefail
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

JQ="jq"

function delete_heroku_app {
    echo "Deleting Heroku app..."
    local NAME=$1
    local RESPONSE="$(curl --silent -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -X DELETE https://api.heroku.com/apps/${NAME} \
        -H "Accept: application/vnd.heroku+json; version=3" \
        -H "Authorization: Bearer $HEROKU_API_KEY" \
        -H "Accept application/json")"
    local ARCHIVED_AT=$(echo ${RESPONSE} | $JQ '.archived_at != null')

    if [[ "$ARCHIVED_AT" != "true" ]]; then
        echo "Could not delete app '$NAME': $(echo ${RESPONSE} | $JQ .message)"
    fi
}

function delete_github_repo {
    echo "Deleting GitHub repository..."
	local NAME=$1
	local CREDENTIALS="$GITHUB_USERNAME:$GITHUB_PERSONAL_ACCESS_TOKEN"
	local STATUS=$(curl --silent -u $CREDENTIALS -H "Accept: application/vnd.github.v3+json" -H "Content-Type: application/json" -X DELETE https://api.github.com/repos/${GITHUB_USERNAME}/${NAME})

    local HAS_ERRORS=$(echo $STATUS | $JQ '.errors | length == 0')
	if [ "${HAS_ERRORS}" == "false" ]; then
        local MESSAGE=$(echo $STATUS | $JQ '.errors[0].message')
	    echo "Failed to create repository '$NAME': $MESSAGE"
	fi
}

APP_NAME=$1

delete_heroku_app ${APP_NAME}
delete_github_repo ${APP_NAME}