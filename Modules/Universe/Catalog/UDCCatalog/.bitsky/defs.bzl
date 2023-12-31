load(
  "//.bitsky:internal_defs.bzl", 
  internal_defs = "defs"
)

package_features = internal_defs.package_features

defs_app_name_list = ["UDCCatalog"]

defs_test_name_list = []

defs_extension_name_list = []

common_copts = internal_defs.common_copts

common_swiftcopts = internal_defs.common_swiftcopts

defs_minimum_os_version = internal_defs.minimum_os_version

for_ios_extension = internal_defs.for_ios_extension

for_application_apple_framework = internal_defs.for_application_apple_framework

for_extension_apple_framework = internal_defs.for_extension_apple_framework

for_external_objc_library = internal_defs.for_external_objc_library

for_external_swift_library = internal_defs.for_external_swift_library

for_extension_objc_library = internal_defs.for_extension_objc_library

for_extension_swift_library = internal_defs.for_extension_swift_library

for_module_objc_library = internal_defs.for_module_objc_library

for_module_swift_library = internal_defs.for_module_swift_library
