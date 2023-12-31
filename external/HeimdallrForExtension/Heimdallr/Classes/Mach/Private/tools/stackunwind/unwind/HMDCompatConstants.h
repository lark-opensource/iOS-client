//
//  HMDCompatConstants.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_COMPAT_CONSTANTS_H
#define HMD_COMPAT_CONSTANTS_H 1

#include <AvailabilityMacros.h>

#include <mach/machine.h>

/*
 * With the introduction of new processor types and subtypes, Apple often does not update the system headers
 * on Mac OS X (and the Simulator). This header provides compatibility defines (and #warnings that will
 * fire when the SDKs are updated to include the required constants.
 */
#define HMDCF_COMPAT_HAS_UPDATED_OSX_SDK(sdk_version) \
    (TARGET_OS_MAC && !TARGET_OS_IPHONE) &&           \
        ((HMDCF_MIN_MACOSX_SDK > sdk_version) || (MAC_OS_X_VERSION_MAX_ALLOWED <= sdk_version))

/* ARM64 compact unwind constants. The iPhoneSimulator 7.0 SDK includes the compact unwind enums,
 * but not the actual CPU_TYPE_ARM64 defines, so we must special case it here. */
#if !defined(CPU_TYPE_ARM64) && !TARGET_IPHONE_SIMULATOR
enum {
    UNWIND_ARM64_MODE_MASK = 0x0F000000,
    UNWIND_ARM64_MODE_FRAME_OLD = 0x01000000,
    UNWIND_ARM64_MODE_FRAMELESS = 0x02000000,
    UNWIND_ARM64_MODE_DWARF = 0x03000000,
    UNWIND_ARM64_MODE_FRAME = 0x04000000,

    UNWIND_ARM64_FRAME_X19_X20_PAIR = 0x00000001,
    UNWIND_ARM64_FRAME_X21_X22_PAIR = 0x00000002,
    UNWIND_ARM64_FRAME_X23_X24_PAIR = 0x00000004,
    UNWIND_ARM64_FRAME_X25_X26_PAIR = 0x00000008,
    UNWIND_ARM64_FRAME_X27_X28_PAIR = 0x00000010,

    UNWIND_ARM64_FRAMELESS_STACK_SIZE_MASK = 0x00FFF000,
    UNWIND_ARM64_DWARF_SECTION_OFFSET = 0x00FFFFFF,
};
#elif HMDCF_COMPAT_HAS_UPDATED_OSX_SDK(MAC_OS_X_VERSION_10_8)
#warning UNWIND_ARM64_* constants are now defined by the minimum supported Mac SDK. Please remove this define.
#endif

/* CPU type/subtype constants */
#ifndef CPU_SUBTYPE_ARM_V7S
#define CPU_SUBTYPE_ARM_V7S 11
#elif HMDCF_COMPAT_HAS_UPDATED_OSX_SDK(MAC_OS_X_VERSION_10_8)
#warning CPU_SUBTYPE_ARM_V7S is now defined by the minimum supported Mac SDK. Please remove this define.
#endif

#ifndef CPU_TYPE_ARM64
#define CPU_TYPE_ARM64 (CPU_TYPE_ARM | CPU_ARCH_ABI64)
#elif HMDCF_COMPAT_HAS_UPDATED_OSX_SDK(MAC_OS_X_VERSION_10_8)
#warning CPU_TYPE_ARM64 is now defined by the minimum supported Mac SDK. Please remove this define.
#endif

#ifndef CPU_SUBTYPE_ARM_V8
#define CPU_SUBTYPE_ARM_V8 13
#elif HMDCF_COMPAT_HAS_UPDATED_OSX_SDK(MAC_OS_X_VERSION_10_8)
#warning CPU_SUBTYPE_ARM_V8 is now defined by the minimum supported Mac SDK. Please remove this define.
#endif

#endif /* HMD_COMPAT_CONSTANTS_H */
