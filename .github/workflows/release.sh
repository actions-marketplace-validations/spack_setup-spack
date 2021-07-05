#!/bin/sh

set -xeu

name="$1"

if [ -z "$name" ]; then
    echo "Provide a release asset name"
    exit 1
else
    echo "Uploading $name"
fi

curl -fsS \
    -H "Accept: application/vnd.github.v3+json" \
    https://github.com/haampie-spack/setup-spack/releases > release_info.json

# Get the release url
release_id="$(< release_info.json jq -r '.[] | select(.tag_name=="develop") | .id')"

if [ -z "$release_id" ]; then
    echo "Couldn't get release id"
    exit 1
fi

echo "Using release id $release_id"

# Get the asset url
asset_url="$(< release_info.json jq -r --arg name "$name" '.[] | select(.tag_name=="develop") | .assets[] | select(.name==$name) | .url')"

# Delete the asset
if [ -n "$asset_url" ]; then
    echo "Deleting remote $name"
    curl -fsS \
            -X DELETE \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "$asset_url"
fi

# Upload a new one.
echo "Uploading $name"
curl -fsS \
        -X POST \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        --data-binary "@$name" \
        "https://uploads.github.com/repos/haampie-spack/setup-spack/releases/$release_id/assets?name=$name)"