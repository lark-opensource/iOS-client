#!/bin/bash
PROG_DIR="$(cd -- "$(dirname "$0")" && pwd -P)"
PROG_NAME=$(basename "$0")

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

print_usage() {
    echo "Usage: $PROG_NAME [options]"
    echo "Run unit test"
    echo "  -h, --help     Display this usage and then exit"
    echo "  -m, --mock_ci  Mock CI environment"
    echo "  -t, --test     Only test without pod install either build"
}

mock_ci="false"
only_test="false"
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_usage
            exit 0
            ;;
        -m | --mock_ci)
            mock_ci="true"
            ;;
        -t | --test)
            only_test="true"
            ;;
    esac
    shift
done

project_dir="$(cd -- "$PROG_DIR/.." && pwd -P)"

export TARGETCODEPATH="$project_dir"
export HOST_APP_XCWORKSPACE="Example/Ecosystem.xcworkspace"
export HOST_APP_SCHEME="Ecosystem"
export HOST_APP_PRODUCT="Ecosystem.app"
export XCODE_UNIT_TEST_CONFIGURATION="Debug"
export XCODE_UNIT_TEST_SDK="iphonesimulator"

run_unit_test_prog="$PROG_DIR/unit_test.sh"

unit_test_cmd="-c -b"
if [ "$only_test" = "true" ]; then
    # 跳过bundle install
    unit_test_cmd="-s"
fi

run_unit_test_cmd="bash $run_unit_test_prog $unit_test_cmd"
if [ "$mock_ci" = "true" ]; then
    run_unit_test_cmd="$run_unit_test_cmd -m"
fi

echo "$run_unit_test_cmd"
eval "$run_unit_test_cmd"
