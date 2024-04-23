#!/bin/bash

# Username of the user whose stars you want to replicate
username="USERNAME"

# Fetch starred repositories and star each for the authenticated user
gh api /users/$username/starred -H "Accept: application/vnd.github+json" \
| jq -r '.[] | "\(.owner.login)/\(.name)"' \
| xargs -L 1 gh api --method PUT /user/starred/{}
