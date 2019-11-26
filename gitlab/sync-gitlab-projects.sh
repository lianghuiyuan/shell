#!/usr/bin/env bash

# should install jq first, for mac:brew install jq

# Documentation
# https://docs.gitlab.com/ce/api/projects.html#list-projects

NAMESPACE="study"
BASE_PATH="https://gitlab.xxxx.net/"
PROJECT_SEARCH_PARAM=""
PROJECT_SELECTION="select(.namespace.name == \"$NAMESPACE\")"

#below use git@xxx to git clone
#PROJECT_PROJECTION="{ "path": .path, "git": .ssh_url_to_repo }"
#below use http:// to git clone
PROJECT_PROJECTION="{ "path": .path, "git": .http_url_to_repo }"

GITLAB_PRIVATE_TOKEN="persional_gitlab_token"

FILENAME="repos.json"

trap "{ rm -f $FILENAME; }" EXIT

curl -s "${BASE_PATH}api/v4/projects?private_token=$GITLAB_PRIVATE_TOKEN&search=$PROJECT_SEARCH_PARAM&per_page=999" \
    | jq --raw-output --compact-output ".[] | $PROJECT_SELECTION | $PROJECT_PROJECTION" > "$FILENAME"

# for debug
# curl -s "https://git.example.com/api/v4/projects?private_token=xxxxxxx" |jq --raw-output --compact-output ".[]|select(.namespace.name == \"live\")|{ \"path\": .path, \"git\": .http_url_to_repo}" > tmp
while read repo; do
    THEPATH=$(echo "$repo" | jq -r ".path")
    GIT=$(echo "$repo" | jq -r ".git")

    if [ ! -d "$THEPATH" ]; then
        echo "Cloning $THEPATH ( $GIT )"
        git clone "$GIT" --quiet &
    else
        echo "Pulling $THEPATH"
        (cd "$THEPATH" && git pull --quiet) &
    fi
done < "$FILENAME"

wait
