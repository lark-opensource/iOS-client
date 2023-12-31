load(
  "//.bitsky:internal_defs.bzl", 
  internal_defs = "defs"
)

package_features = internal_defs.package_features

defs_app_name_list = ["LarkMessengerDemo", "UnitTestHost", "LarkMessengerDemoMockFeeds"]

defs_test_name_list = ["LarkMessengerUnitTest", "LarkMessengerDemoMockFeedsUITests"]

defs_extension_name_list = []

common_copts = internal_defs.common_copts

common_swiftcopts = internal_defs.common_swiftcopts

defs_minimum_os_version = internal_defs.minimum_os_version

for_ios_application = struct(
    features = select({
        "//conditions:default": [],
        "//conditions:release": [
            "thin_lto",
        ],
    }),
    linker = "//.bitsky:kun_ld",
    linkopts = select({
        "//conditions:default": [],
        "//conditions:debug": [
            "-dead_strip",
        ],
    }) + [
        "-v",
        "-ObjC",
        "-dead_strip",
        "-no_deduplicate",
        "-no_adhoc_codesign",
        "-print_statistics",
        "-objc_abi_version",
        "2",
    ],
)

for_ios_extension = internal_defs.for_ios_extension

for_application_apple_framework = internal_defs.for_application_apple_framework

for_extension_apple_framework = internal_defs.for_extension_apple_framework

for_external_objc_library = internal_defs.for_external_objc_library

for_external_swift_library = internal_defs.for_external_swift_library

for_extension_objc_library = internal_defs.for_extension_objc_library

for_extension_swift_library = internal_defs.for_extension_swift_library

for_module_objc_library = internal_defs.for_module_objc_library

for_module_swift_library = internal_defs.for_module_swift_library
