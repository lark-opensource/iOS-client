//
//  lk_section_data_utility
//
//  Created by Sniper on 2020/11/8.
//


#ifndef LKSectionDataUtility_h
#define LKSectionDataUtility_h

#include <stdio.h>
#include <mach-o/loader.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;

#else
typedef struct mach_header mach_header_t;
#endif

#if __has_feature(address_sanitizer)
// https://github.com/llvm-mirror/compiler-rt/blob/57470fcc23ff27e2dbbcc2a04254a3879977d9ce/lib/asan/asan_interface_internal.h
typedef uintptr_t * uptr;
// This structure is used to describe the source location of a place where
// global was defined.
struct __asan_global_source_location {
    const char *filename;
    int line_no;
    int column_no;
};

// This structure describes an instrumented global variable.
struct __asan_global_var {
    uptr beg;                // The address of the global.
    uptr size;               // The original size of the global.
    uptr size_with_redzone;  // The size with the redzone.
    const char *name;        // Name as a C string.
    const char *module_name; // Module name as a C string. This pointer is a
    // unique identifier of a module.
    uptr has_dynamic_init;   // Non-zero if the global has dynamic initializer.
    struct __asan_global_source_location *location;  // Source location of a global,
    // or NULL if it is unknown.
    uptr odr_indicator;      // The address of the ODR indicator symbol.
};
#endif

#define LK_SECTION_DATA(sectname) __attribute((used, section("__DATA,"#sectname)))

#define LK_SECTION_DATA_REGISTER(sectname,name) const char * k_##name##_sectdata LK_SECTION_DATA(sectname) = #name;
#ifdef __cplusplus
extern "C" {
#endif
    char const ** lk_get_sectiondata_with_name(char *section_name, unsigned long *size);
#ifdef __cplusplus
}
#endif
#endif /* LKSectionDataUtility_h */
