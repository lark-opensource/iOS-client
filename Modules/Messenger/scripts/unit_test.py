#!/usr/bin/env python3
# -*- coding:utf-8 -*-

import os
import sys
import argparse
import json
import subprocess
import plistlib
import logging

_COMMAND_MAX_RETRIES = 2
_CORESIMULATOR_INTERRUPTED_ERROR = "CoreSimulatorService connection interrupted"

_ERROR_CODE_INVALID_DESTINATION = 51
_ERROR_CODE_XCODEBUILD_BUILD = 52
_ERROR_CODE_XCODEBUILD_TEST = 53


def _add_quote_if_contains_space(x):
    if not x or len(x.split()) <= 1:
        return x
    return '"{}"'.format(x)


def _run_cmd(command, realtime_output=False, use_shell=False):
    output_pipe = None if realtime_output else subprocess.PIPE
    for i in range(_COMMAND_MAX_RETRIES):
        if use_shell:
            command = " ".join(map(_add_quote_if_contains_space, command))
            logging.info(command)
        with subprocess.Popen(command,
                              stdout=output_pipe,
                              stderr=output_pipe,
                              shell=use_shell,
                              encoding="utf-8") as process:
            stdout, stderr = process.communicate()
            if realtime_output:
                # Just return if realtime output is needed
                return ("", process.returncode)

            all_output = "\n".join([stdout, stderr])
            output = stdout.strip()
            if process.poll() != 0:
                if (i < (_COMMAND_MAX_RETRIES - 1)
                        and _CORESIMULATOR_INTERRUPTED_ERROR in all_output):
                    continue
                return ("", process.returncode)
            return (output, process.returncode)


def _run_xcrun_cmd(extra_args):
    return _run_cmd(["xcrun"] + extra_args)


def _run_simctl_cmd(extra_args):
    output, _ = _run_xcrun_cmd(["simctl"] + extra_args)
    return output


def _run_xcodebuild_cmd(extra_args):
    _, return_code = _run_cmd(["xcodebuild"] + extra_args,
                              realtime_output=True,
                              use_shell=True)
    return return_code


def _get_sdk_platform_path(sdk):
    output, _ = _run_xcrun_cmd(["--sdk", sdk, "--show-sdk-platform-path"])
    return output


def _extra_os_version(os_version_str):
    # Cut build version. E.g., cut 9.3.3 to 9.3.
    if os_version_str.count(".") > 1:
        os_version_str = os_version_str[:os_version_str.rfind(".")]
    # We need to round the os version string in the simulator profile. E.g.,
    # the maxRuntimeVersion of iPhone 5 is 10.255.255 and we could
    # create iOS 10.3 for iPhone 5.
    return round(float(os_version_str), 1)


def _parse_key(target_object, key):
    if isinstance(target_object, dict):
        return key
    if isinstance(target_object, list):
        try:
            return int(key)
        except ValueError as err:
            raise Exception(
                "The key '{}' is invaild index of list(array) object {}.".
                format(key, target_object)) from err
    raise Exception("The object {} is not dict or list.".format(target_object))


def _get_object_with_field(target_object, field):
    if not field:
        return target_object
    current_object = target_object
    for key in field.split(":"):
        try:
            current_object = current_object[_parse_key(current_object, key)]
        except (KeyError, IndexError) as err:
            raise Exception("The field '{}' can not be found " \
                            "in the target object.".format(field)) from err
        except Exception as err:
            raise err
    return current_object


def _get_sim_min_os_version(sim_types_info):
    if "minRuntimeVersionString" in sim_types_info:
        logging.debug("Found 'minRuntimeVersionString' in device type info.")
        logging.info("Retrieve 'minRuntimeVersion' from the value of " \
                     "'minRuntimeVersionString' of device type info")
        return sim_types_info["minRuntimeVersionString"]
    else:
        if "bundlePath" in sim_types_info:
            logging.info("Retrieve profile.plist from the value of " \
                         "'bundlePath' of device type info.")
            profile_plist_path = os.path.join(
                sim_types_info["bundlePath"],
                "Contents/Resources/profile.plist")
        else:
            logging.info("Retrieve profile.plist manually.")
            platform_path = _get_sdk_platform_path("iphoneos")

            # Assume Xcode version is greater than 11.0
            sim_profiles_dir = os.path.join(
                platform_path, "Library/Developer/CoreSimulator/Profiles")
            profile_plist_path = os.path.join(
                sim_profiles_dir,
                "DeviceTypes/{}.simdevicetype/Contents/Resources/profile.plist".
                format(sim_types_info["name"]))

        logging.info("Retrieve 'minRuntimeVersion' from '%s'.",
                     profile_plist_path)
        with open(profile_plist_path, "rb") as plist_file:
            plist_root_object = plistlib.load(plist_file)
            return _get_object_with_field(plist_root_object,
                                          "minRuntimeVersion")


def _get_last_supported_iphone_sim_type(os_version):
    try:
        supported_ios_sim_types = []
        sim_types_infos_json = json.loads(
            _run_simctl_cmd(["list", "devicetypes", "-j"]))
        for sim_types_info in sim_types_infos_json["devicetypes"]:
            sim_type = sim_types_info["name"]
            if sim_type.startswith("iPhone"):
                supported_ios_sim_types.append(sim_types_info)
        supported_ios_sim_types.reverse()

        os_version_float = float(os_version)
        for sim_types_info in supported_ios_sim_types:
            min_os_version_float = _extra_os_version(
                _get_sim_min_os_version(sim_types_info))
            if os_version_float >= min_os_version_float:
                return sim_types_info["name"]
    except Exception as err:
        logging.error("Exception(%s), %s", type(err).__name__, err)

    logging.error("Can not find supported iPhone simulator type of " \
                  "OS version('%s').", os_version)
    return ""


def _get_last_simulator_os_version(os_type="iOS"):
    sim_versions = []
    try:
        sim_runtime_infos_json = json.loads(
            _run_simctl_cmd(["list", "runtimes", "-j"]))
        for sim_runtime_info in sim_runtime_infos_json["runtimes"]:
            # `platform` key may not exist in some Xcode/macOS version.
            if "platform" in sim_runtime_info:
                if sim_runtime_info["platform"] == os_type:
                    logging.debug("Retrieve last os version from 'platform' " \
                                  "of runtime info.")
                    sim_versions.append(sim_runtime_info["version"])
            else:
                listed_name = sim_runtime_info["name"]
                listed_os_type, listed_os_version = listed_name.split(" ", 1)
                if listed_os_type == os_type:
                    logging.debug("Retrieve last os version from 'name' " \
                                  "of runtime info.")
                    sim_versions.append(listed_os_version)
    except Exception as err:
        sim_versions.clear()
        logging.error("Exception(%s), %s", type(err).__name__, err)

    if not sim_versions:
        logging.error("Can not find supported OS version of '%s'.", os_type)
        return "0"

    last_os_version = sim_versions[-1]
    logging.debug("Last os version is '%s'.", last_os_version)
    return last_os_version


def _run_unit_test(workspace, scheme, configuration, sdk, destination,
                   derived_data_path, output, always_build, clean, xcpretty):
    if not sdk:
        sdk = "iphonesimulator"

    if not destination:
        os_version = _get_last_simulator_os_version()
        sim_type_name = _get_last_supported_iphone_sim_type(os_version)
        if sim_type_name:
            destination = "platform=iOS Simulator,name={}".format(sim_type_name)
        else:
            logging.error("Invalid destination")
            return _ERROR_CODE_INVALID_DESTINATION

    if not derived_data_path:
        derived_data_path = os.path.join(os.path.dirname(workspace),
                                         "DerivedData")

    xcodebuild_log_filename = "xcodebuild_unit_test.log"
    xcodebuild_log_file = os.path.join(output, xcodebuild_log_filename)
    try:
        if not os.path.exists(output):
            os.makedirs(output)
        if os.path.isfile(xcodebuild_log_file):
            os.remove(xcodebuild_log_file)
    except:
        pass

    logging.info("Xcode workspace: '%s'", workspace)
    logging.info("Build scheme: '%s'", scheme)
    logging.info("Build configuration: '%s'", configuration)
    logging.info("Build sdk: '%s'", sdk)
    logging.info("Destination: '%s'", destination)
    logging.info("Derived data path: '%s'", derived_data_path)

    xcodebuild_args = [
        "-workspace", workspace, "-scheme", scheme, "-configuration",
        configuration, "-sdk", sdk, "-destination", destination,
        "-derivedDataPath", derived_data_path
    ]

    xcpretty_args = []
    if xcpretty:
        # Make sure that `xcodebuild_log_file` is a regular file
        if (os.path.isdir(output) and (not os.path.exists(xcodebuild_log_file)
                                       or os.path.isfile(xcodebuild_log_file))):
            xcpretty_args += ["|", "tee", "-a", xcodebuild_log_file]
        xcpretty_args += ["|", "xcpretty", "&&", "exit", "${PIPESTATUS[0]}"]

    if clean:
        logging.info("Run 'clean'")
        _run_xcodebuild_cmd(xcodebuild_args + ["clean"] + xcpretty_args)

    if always_build:
        logging.info("Run 'build'")
        return_code = _run_xcodebuild_cmd(xcodebuild_args + ["build"] +
                                          xcpretty_args)
        if return_code != 0:
            return _ERROR_CODE_XCODEBUILD_BUILD

    logging.info("Run 'test'")
    return_code = _run_xcodebuild_cmd(xcodebuild_args +
                                      ["-enableCodeCoverage", "YES", "test"] +
                                      xcpretty_args)
    if return_code != 0:
        return _ERROR_CODE_XCODEBUILD_TEST
    return return_code


def _verify_xcworkspace(workspace):
    if not os.path.isdir(workspace):
        msg = "No such xcode workspace: '{}'.".format(workspace)
        raise argparse.ArgumentTypeError(msg)
    elif not os.path.isfile(os.path.join(workspace,
                                         "contents.xcworkspacedata")):
        msg = "Invalid xcode workspace: '{}'.".format(workspace)
        raise argparse.ArgumentTypeError(msg)
    return os.path.abspath(workspace)


def _parse_args():
    parser = argparse.ArgumentParser(
        description="Run unit test",
        formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-w",
                        "--workspace",
                        type=_verify_xcworkspace,
                        required=True,
                        help="Workspace that includes the unit test")
    parser.add_argument("-s",
                        "--scheme",
                        type=str,
                        required=True,
                        help="Use the scheme to run unit test")
    parser.add_argument("-C",
                        "--configuration",
                        type=str,
                        choices=["Debug", "Release"],
                        default="Debug",
                        help="Use the scheme to run unit test")
    parser.add_argument("-S",
                        "--sdk",
                        type=str,
                        choices=["iphonesimulator", "iphoneos"],
                        default="iphonesimulator",
                        help="Use the SDK when building the project")
    parser.add_argument("-d",
                        "--destination",
                        type=str,
                        help="Use the destination to run unit test")
    parser.add_argument("-D",
                        "--derived_data_path",
                        dest="derived_data_path",
                        type=str,
                        help="Specifies the directory where build products " \
                             "and other derived data will go.\n" \
                             "Use `dirname WORKSPACE`/DerivedData by default")
    parser.add_argument("-o", "--output", type=str, help="Output path")
    parser.add_argument("-b",
                        "--always_build",
                        dest="always_build",
                        action="store_true",
                        help="Build the scheme before testing")
    parser.add_argument("-c",
                        "--clean",
                        action="store_true",
                        help="Clean before building or testing")
    parser.add_argument("-p",
                        "--xcpretty",
                        action="store_true",
                        help="Use xcpretty to format the output of xcodebuild")
    parser.add_argument("--verbose",
                        action="store_true",
                        help="Print additional logging information")
    return parser.parse_args()


def main():
    args = _parse_args()

    logging.basicConfig(
        format="[%(levelname)s][%(filename)s:%(lineno)d]: %(message)s",
        level=logging.DEBUG if args.verbose else logging.INFO)
    logging.debug(args)

    return_code = _run_unit_test(args.workspace, args.scheme,
                                 args.configuration, args.sdk, args.destination,
                                 args.derived_data_path, args.output,
                                 args.always_build, args.clean, args.xcpretty)
    sys.exit(return_code)


if __name__ == "__main__":
    main()
