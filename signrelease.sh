#!/bin/bash
# Signs a release according to https://wiki.debian.org/Creating%20signed%20GitHub%20releases
#
# LICENSE: CC0/Public Domain - To the extent possible under law, rugk has waived all copyright and related or neighboring rights to this work. This work is published from: Deutschland.
#
# NOTE: For the ZIP verification to work you need at least git v2.4.0.
# Explanation: The reason is that prior to v2.4.0 all files are marked as binary and this information is saved in the ZIP file. As GitHub uses a more recent version of git this means most files are marked as text or so there, so that the ZIPs are different.
# (Thanks to GitHub's support/Jeff King for this information.)
#

CURR_DIR="$( pwd )"
ARCHIVE_TYPES="tar.gz zip"
OPEN_COMMAND="xdg-open"
# OPEN_COMMAND="nautilus"

# When creating ZIP files the time zone matters. As GitHub uses the local time
# zone when creating the archives we need to replicate this behaviour.
# (Thanks to the GitHub support for this information!)
GITHUB_TIME_ZONE="PST8PDT"

echo "Executed in $CURR_DIR."
echo "NOTE: You already need to have a published release on GitHub."

# ask for values
projectDefault="$( cat .git/description )"
if [ "${projectDefault}" = "Unnamed repository; edit this file 'description' to name the repository." ]; then
    projectDefault=$(basename "$CURR_DIR")
fi

read -rp "Enter the project name [${projectDefault}]: " project
project=${project:-$projectDefault}

read -rp "Enter the tag to sign: " tag
if [ "${tag}" = "" ]; then
    exit 1
fi

originGitHubDefault="$( git config --get remote.origin.url )"
read -rp "Paste GitHub URL here [${originGitHubDefault}]: " originGitHub
originGitHub=${originGitHub:-$originGitHubDefault}

# pre-processing
TMP_DIR="$(mktemp --tmpdir -d "signrelease/${project}-${tag}-XXXXXXXXXX")"

#
# CREATE LOCAL ARCHIVES
#

# verify tag

if ! git verify-tag "${tag}"; then
    echo "WARNING: The git tag is not signed yet (or does not exist). It should (also) be signed."

    read -rp "Continue anyway? [y/N] " skipWarn
    if [ "${skipWarn}" != "y" ]; then
        exit 1
    fi
fi

# create archive
for ext in $ARCHIVE_TYPES; do
    echo git archive --prefix="${project}-${tag}/" -o "$TMP_DIR/${project}-${tag}.${ext}" "${tag}"

    if ! TZ=$GITHUB_TIME_ZONE git archive --prefix="${project}-${tag}/" -o "$TMP_DIR/${project}-${tag}.${ext}" "${tag}"; then
        echo "FATAL ERROR: The git archive could not be created."
        exit 2
    fi
done

#
# VERIFY/COMPARE FILES
#

for ext in $ARCHIVE_TYPES; do
    # download file from GitHub
    wget -q "${originGitHub}/archive/${tag}.${ext}" -O "$TMP_DIR/GitHubDownloadedArchive.${ext}"

    # compare with GitHub version
    if ! diff -s "$TMP_DIR/${project}-${tag}.${ext}" "$TMP_DIR/GitHubDownloadedArchive.${ext}"; then
        echo "FATAL ERROR: GitHubs downloaded ${ext} archive file is different from our own."
        exit 2
    fi

    # sign archive
    gpg --armor --detach-sign "$TMP_DIR/${project}-${tag}.${ext}"
done


#
# END
#

# clean up
for ext in $ARCHIVE_TYPES; do
    rm "$TMP_DIR/GitHubDownloadedArchive.${ext}"
done
for ext in $ARCHIVE_TYPES; do
    rm "$TMP_DIR/${project}-${tag}.${ext}"
done

echo "Ńow you can upload the *.asc files"
echo "  from $TMP_DIR"
echo "  to ${originGitHub}/releases/edit/${tag}"
echo "."

# open dir in file manager
setsid $OPEN_COMMAND "$TMP_DIR"

