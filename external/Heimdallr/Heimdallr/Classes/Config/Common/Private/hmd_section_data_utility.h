//
//  hmd_section_data_utility
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//
//==============================================================================
//
//Copyright (c) 2009-2015 Craig van Vliet, Edward O'Callaghan, Howard Hinnant, Guan-Hong Liu, Joerg Sonnenberger and Matt Thomas
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.
//
//==============================================================================

#ifndef HMDSectionDataUtility_h
#define HMDSectionDataUtility_h

#include <stdio.h>
#include <mach-o/loader.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;

#else
typedef struct mach_header mach_header_t;
#endif

//https://github.com/llvm-mirror/compiler-rt/blob/57470fcc23ff27e2dbbcc2a04254a3879977d9ce/lib/asan/asan_interface_internal.h
#if __has_feature(address_sanitizer)
typedef uintptr_t * uptr;
// This structure is used to describe the source location of a place where
// global was defined.
struct __asan_global_var_source_location {
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
    struct __asan_global_var_source_location *location;  // Source location of a global,
    // or NULL if it is unknown.
    uptr odr_indicator;      // The address of the ODR indicator symbol.
};
#endif


#define HMD_SECTION_DATA(sectname) __attribute((used, section("__DATA,"#sectname)))

#define HMD_SECTION_DATA_REGISTER(sectname,name) const char * k_##name##_sectdata HMD_SECTION_DATA(sectname) = #name;

#define HMD_MODULE_CONFIG(name) HMD_SECTION_DATA_REGISTER(HMDModule,name)

#define HMD_LOCAL_MODULE_CONFIG(name) HMD_SECTION_DATA_REGISTER(HMDLocalModule,name)

#ifdef __cplusplus
extern "C" {
#endif
    char const ** hmd_get_sectiondata_with_name(char *section_name, unsigned long *size);
#ifdef __cplusplus
}
#endif
#endif /* HMDSectionDataUtility_h */
