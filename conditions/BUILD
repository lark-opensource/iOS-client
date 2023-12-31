load("@bazel_skylib//lib:selects.bzl", "selects")

package(
    default_visibility = ["//visibility:public"],
)

# xcodebuild -showsdks
xcode_version(
    name = "xcode14.1.0",
    default_ios_sdk_version = "16.1",
    default_macos_sdk_version = "13.0",
    default_tvos_sdk_version = "16.1",
    default_watchos_sdk_version = "9.1",
    version = "14.1.0",
)

xcode_version(
    name = "xcode14.2.0",
    default_ios_sdk_version = "16.2",
    default_macos_sdk_version = "13.1",
    default_tvos_sdk_version = "16.2",
    default_watchos_sdk_version = "9.1",
    version = "14.2.0",
)

available_xcodes(
    name = "local_xcodes",
    default = ":xcode14.1.0",
    versions = [":xcode14.1.0", ":xcode14.2.0"],
)

available_xcodes(
    name = "remote_xcodes",
    default = ":xcode14.1.0",
    versions = [":xcode14.1.0"],
)

xcode_config(
    name = "host_xcodes",
    local_versions = ":local_xcodes",
    remote_versions = ":remote_xcodes",
)

config_setting(
    name = "debug",
    values = {
        "compilation_mode": "dbg",
    },
)

config_setting(
    name = "release",
    values = {
        "compilation_mode": "opt",
    },
)

config_setting(
    name = "xcode_14_any",
    flag_values = {
        "@bazel_tools//tools/osx:xcode_version_flag_major": "14",
    },
)

config_setting(
    name = "lark",
    define_values = {
        "TARGET_NAME": "Lark",
    },
)
