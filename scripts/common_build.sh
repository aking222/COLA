#!/bin/bash
[ -z "${__source_guard_7D8ED8FF_636B_4D66_95D7_9D46FE180F0F:+dummy}" ] || return 0
__source_guard_7D8ED8FF_636B_4D66_95D7_9D46FE180F0F=true

# shellcheck source=common.sh
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"

################################################################################
# build util functions
################################################################################

__getMvnwExe() {
    local maven_wrapper_name="mvnw"

    local d="$PWD"
    while true; do
        [ "/" = "$d" ] && die "Fail to find $maven_wrapper_name!"
        [ -f "$d/$maven_wrapper_name" ] && break

        d=$(dirname "$d")
    done

    echo "$d/$maven_wrapper_name"
}

__getJavaVersion() {
    cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../cola-components/" &&
        ./mvnw -v | awk -F': |,' '/^Java version/ {print $2}'
}

__getMoreMvnOptionsWhenJdk11() {
    local javaVersion
    javaVersion=$(__getJavaVersion)
    if ! versionLessThan $javaVersion 11 && versionLessThan $javaVersion 12; then
        echo -DperformRelease -P'!gen-sign'
    fi
}

readonly -a _MVN_BASIC_OPTIONS=(
    -V --no-transfer-progress
)
readonly -a _MVN_OPTIONS=(
    "${_MVN_BASIC_OPTIONS[@]}"
    $(__getMoreMvnOptionsWhenJdk11)
)

MVN() {
    logAndRun "$(__getMvnwExe)" "${_MVN_OPTIONS[@]}" "$@"
}

MVN_WITH_BASIC_OPTIONS() {
    logAndRun "$(__getMvnwExe)" "${_MVN_BASIC_OPTIONS[@]}" "$@"
}

# Where is Maven local repository?
#   https://mkyong.com/maven/where-is-maven-local-repository/

# NOTE: DO NOT declare mvn_local_repository_dir var as readonly, its value is supplied by subshell.
mvn_local_repository_dir="$(
    cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../cola-components/" &&
        ./mvnw --no-transfer-progress help:evaluate -Dexpression=settings.localRepository |
        grep '^/'
)"
[ -n "$mvn_local_repository_dir" ] || die "Fail to find find maven local repository directory: $mvn_local_repository_dir"

echo "find maven local repository directory: $mvn_local_repository_dir"

cleanMavenInstallOfColaInMavenLocalRepository() {
    headInfo "clean maven build and install of COLA in maven local repository:"
    logAndRun -s rm -rf "$mvn_local_repository_dir/com/alibaba/demo"
    logAndRun -s rm -rf "$mvn_local_repository_dir/com/alibaba/cola"
    logAndRun -s rm -rf "$mvn_local_repository_dir/com/alibaba/craftsman"
}
