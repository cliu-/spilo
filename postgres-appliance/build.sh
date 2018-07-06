#!/bin/bash
set -ex
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--debug)
            DEBUG="true"
        ;;
        -n|--name )
            NAME="$2"
            shift
            ;;
        -v|--version )
            VERSION="$2"
            shift
            ;;
        --build-arg )
            build_args+=("$1" "$2")
            shift
            ;;
        * )
            build_args+=("$1")
            final_args+=("$1")
            ;;
    esac
    shift
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

IMGBUILD="$NAME-build:$VERSION"
IMG="$NAME:$VERSION"

x_build_args="${build_args[@]}"
x_final_args="${final_args[@]}"
[ $DEBUG == "true" ] && x_build_args="$x_build_args --build-arg DEBUG=true" \
&& x_final_args="$x_final_args --build-arg DEBUG=true"

echo "$DEBUG" "$x_build_args" "$x_final_args"

readonly REV=$(git rev-parse HEAD)
readonly URL=$(git config --get remote.origin.url)
readonly STATUS=$(git status --porcelain)
readonly GITAUTHOR=$(git show -s --format="%aN <%aE>" "$REV")

cat > $DIR/scm-source.json <<__EOT__
{
    "url": "git:$URL",
    "revision": "$REV",
    "author": "$GITAUTHOR",
    "status": "$STATUS"
}
__EOT__

function run_or_fail() {
    "$@"
    local EXITCODE=$?
    if  [[ $EXITCODE != 0 ]]; then
        echo "'$@' failed with exitcode $EXITCODE"
        exit $EXITCODE
    fi
}

readonly OLD_BUILD_ID=$(docker images -q $IMGBUILD)

# function squash_new_image() {
#     local NEW_BUILD_ID=$(docker images -q $IMAGE_BASE)
#     local TAG_OF=$(docker images --format "{{.ID}} {{.Repository}}:{{.Tag}}" \
#             | grep "^$NEW_BUILD_ID " | grep -v "^$NEW_BUILD_ID $IMAGE_BASE" \
#             | awk '{print $2; exit 0}')

#     # new "-build" image has the same id as already exiting one
#     [[ ! -z $TAG_OF ]] && docker tag ${TAG_OF%-build}-squashed $IMGNAME-squashed && return 0

#     [[ "$OLD_BUILD_ID" != "$NEW_BUILD_ID" || -z "$(docker images -q $IMGNAME-squashed)" ]] \
#             && run_or_fail docker-squash -t $IMGNAME-squashed $IMGNAME-build
# }

run_or_fail docker build $x_build_args -t $IMGBUILD -f $DIR/Dockerfile.build $DIR

# squash_new_image

# run_or_fail docker tag $IMGNAME-build spilo-base:squashed

run_or_fail docker build $x_final_args -t $IMG -f $DIR/Dockerfile $DIR
