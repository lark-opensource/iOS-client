package_features = [
    "no_quote_include_builtin_dirs",
    "swift.supports_objc_interop",
    "module_name_as_archive_base",
    "swift.module_name_as_archive_base",
    "no_objc_msgsend_selector_stubs",
    "swift.no_objc_msgsend_selector_stubs",
    "-no_autolink",
    "-optional_compile_flags",
    "-default_dbg_compile_flags",
    "-default_opt_compile_flags",
    "-apply_default_warnings",
    "-headerpad",
    "-module_maps",
    "dead_strip",
    "swift.use_global_module_cache",
    "swift.no_generated_module_map",
    "swift.opt_uses_osize",
]

defs_app_name_list = ["Lark"]

defs_test_name_list = []

defs_extension_name_list = [
    "ShareExtension",
    "BroadcastUploadExtension",
    "NotificationServiceExtension",
    "NotificationContentExtension",
    "SmartWidgetExtension",
    "IntentsExtension",
    "LarkAppIntents",
]

defs_minimum_os_version = "12.0"

default_copts = [
    "-g",
    "-DCOCOAPODS=1",
] + select({
    "//conditions:debug": [
        "-O0",
        "-DDEBUG=1",
        "-DPOD_CONFIGURATION_DEBUG=1",
    ],
    "//conditions:release": [
        "-DNDEBUG=1",
        "-DNS_BLOCK_ASSERTIONS=1",
        "-DPOD_CONFIGURATION_RELEASE=1",
        "-Wno-unused-variable",
        "-Winit-self",
        "-Wno-extra",
    ],
})

default_common_cxxopts = []

defs_oz_copts = select({
    "//conditions:default": [],
    "//conditions:release": [
        "-Oz",
    ],
})

defs_o2_copts = select({
    "//conditions:default": [],
    "//conditions:release": [
        "-O2",
    ],
})

defs_defined_copts = select({
    "//conditions:default": [],
})

defs_common_copts = default_copts + defs_o2_copts + defs_defined_copts

default_swiftcopts = [
    "-DCOCOAPODS",
    "-Xcc",
    "-DCOCOAPODS=1",    
    "-Xcc",
    "-Wno-error=non-modular-include-in-framework-module",
    "-no-verify-emitted-module-interface"
] + select({
    "//conditions:debug": [
        "-Xcc",
        "-O0",
        "-DDEBUG",
        "-Xcc",
        "-DDEBUG=1",
        "-Xcc",
        "-DPOD_CONFIGURATION_DEBUG=1",
    ],
    "//conditions:release": [
        "-Xcc",
        "-DNDEBUG=1",
        "-Xcc",
        "-DNS_BLOCK_ASSERTIONS=1",
        "-Xcc",
        "-DPOD_CONFIGURATION_RELEASE=1",
        "-Xcc",
        "-Wno-unused-variable",
        "-Xcc",
        "-Winit-self",
        "-Xcc",
        "-Wno-extra",
    ],
})

defs_oz_swiftcopts = select({
    "//conditions:default": [],
    "//conditions:release": [
        "-Xcc",
        "-Oz",
    ],
})

defs_common_swiftcopts = default_swiftcopts

for_ios_application = struct(
    features = select({
        "//conditions:default": [],
        "//conditions:release": [
            "thin_lto",
        ],
    }),
    exported_symbols_lists = ["//bin:export_symbol_file.txt"],
    linker = "//.bitsky:kun_ld",
    frameworks = [],
    additional_linker_inputs = select({
        "//conditions:lark": ["//:lark.order"],
        "//conditions:default": [],
    }),
    linkopts = select({
        "//conditions:default": [],
        "//conditions:debug": [
            "-dead_strip",
        ],
    }) + select({
        "//conditions:default": [],
        "//conditions:lark": [
            "-order_file",
            "$(location //:lark.order)",
            "-order_file_statistics"
        ],
    }) + [
        "-v",
        "-ObjC",
        "-dead_strip",
        # "-export_dynamic",
        "-no_deduplicate",
        "-no_adhoc_codesign",
        "-print_statistics",
        "-objc_abi_version",
        "2",
    ],
    on_demand_resources = {},
)

for_ios_extension = struct(
    additional_linker_inputs = [],
    linker = "//.bitsky:ji_ld",
    linkopts = select({
        "//conditions:default": [],
        "//conditions:debug": [
            "-dead_strip",
        ],
    }),
)

for_application_apple_framework = struct(
    objc_copts = default_copts + defs_oz_copts + defs_defined_copts,
    swift_copts = default_swiftcopts + defs_oz_swiftcopts,
)

for_extension_apple_framework = struct(
    objc_copts = default_copts + defs_oz_copts + defs_defined_copts,
    swift_copts = default_swiftcopts + defs_oz_swiftcopts,
)

for_extension_objc_library = struct(
    features = [],
    copts = default_copts + defs_oz_copts + defs_defined_copts,
)

for_extension_swift_library = struct(
    features = [],
    copts = default_swiftcopts + defs_oz_swiftcopts,
)

for_external_objc_library = struct(
    common_copts = default_copts + ["-w -Xanalyzer -analyzer-disable-all-checks"],
    RustPB_features = ["swift.split_derived_files_generation"],
    ServerPB_features = ["swift.split_derived_files_generation"],
    common_features = select({
        "//conditions:release": [],
        "//conditions:default": [],
    }),
    Lynx_copts = ["-Wno-deprecated-declarations"],
    MMKVCore_copts = ["-fno-objc-arc"],
)

for_external_swift_library = struct(
    common_copts = default_swiftcopts + ["-suppress-warnings"],    
    LarkFlutterContainer_copts = [
        "-Xcc",
        "-Wno-error=non-modular-include-in-framework-module",
    ],
    MeegoMod_copts = [
        "-DMessengerMod",
        "-DLarkOpenPlatform",
        "-DCCMMod",
        "-Xcc",
        "-Wno-error=non-modular-include-in-framework-module",
    ],
    LarkMeego_copts = [
        "-Xcc",
        "-Wno-error=non-modular-include-in-framework-module",
        "-DMessengerMod",
    ],
    common_features = select({
        "//conditions:release": [],
        "//conditions:default": [],
    }),
)

for_module_objc_library = struct(
    common_copts = defs_common_copts,
    common_cxxopts = default_common_cxxopts,
    common_features = select({
        "//conditions:release": [],
        "//conditions:default": [],
    })
)

for_module_swift_library = struct(
    common_copts = defs_common_swiftcopts,
    common_features = select({
        "//conditions:release": [],
        "//conditions:default": [],
    })
)


defs = struct(
    package_features = package_features,
    app_name_list = defs_app_name_list,
    test_name_list = defs_test_name_list,
    extension_name_list = defs_extension_name_list,
    minimum_os_version = defs_minimum_os_version,
    common_copts = defs_common_copts,
    common_swiftcopts = defs_common_swiftcopts,
    for_ios_application = for_ios_application,
    for_ios_extension = for_ios_extension,
    for_application_apple_framework = for_application_apple_framework,
    for_extension_apple_framework = for_extension_apple_framework,
    for_extension_objc_library = for_extension_objc_library,
    for_extension_swift_library = for_extension_swift_library,
    for_external_objc_library = for_external_objc_library,
    for_external_swift_library = for_external_swift_library,
    for_module_objc_library = for_module_objc_library,
    for_module_swift_library = for_module_swift_library,
)
