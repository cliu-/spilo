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

readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ -z $NAME ] && NAME=spilo
[ -z $VERSION ] && VERSION=0.1 ## Do NOT user "lastest" as version
readonly NAME_BUILD="$NAME-build"
x_build_args="${build_args[@]}"
x_final_args="${final_args[@]}"
[ $DEBUG == "true" ] && x_build_args="$x_build_args --build-arg DEBUG=true" \
&& x_final_args="$x_final_args --build-arg DEBUG=true"

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

[ ! -z $(docker images -q $NAME_BUILD:$VERSION) ] \
    && echo "The image $NAME_BUILD:$VERSION is existed already, change value for \"-v\" and try again." \
    && exit 1
[ ! -z $(docker images -q $NAME-squashed:$VERSION) ] \
    && echo "The image $NAME-squashed:$VERSION is existed already, change value for \"-v\" and try again." \
    && exit 1

run_or_fail docker build $x_build_args -t $NAME_BUILD:$VERSION -f $DIR/Dockerfile.build $DIR

run_or_fail docker-squash -t $NAME-squashed:$VERSION $NAME_BUILD:$VERSION

run_or_fail docker tag $NAME-squashed:$VERSION spilo-base:squashed

run_or_fail docker build $x_final_args -t $NAME:$VERSION -f $DIR/Dockerfile $DIR
