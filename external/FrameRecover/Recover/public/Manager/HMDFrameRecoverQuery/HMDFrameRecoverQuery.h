//
//  HMDFrameRecoverQuery.h
//  FrameRecover
//
//  Created by sunrunwang on 2021/12/24.
//

#ifndef HMDFrameRecoverQuery_h
#define HMDFrameRecoverQuery_h

#include <sys/types.h>
#include <mach/mach.h>
#include <mach-o/loader.h>
#include <mach/vm_map.h>
#include <mach/vm_statistics.h>
#include <stdint.h>
#include <stdbool.h>
#include "HMDFrameRecoverPublicMacro.h"

HMDFC_EXTERN_SCOPE_BEGIN

#pragma mark - Image Info v1

typedef struct hmdfc_image_info {
    vm_address_t header_addr;
    bool         image_from_app;
    ptrdiff_t    slide;
    struct {
        vm_address_t addr;
        vm_size_t size;
    } unwind_info;
    struct {
        struct {
            uint64_t vmaddr_slided;
            uint64_t vmsize;
            uint64_t fileoff;
        } linkedit;
        struct symtab_command symbol_table;
    } symbolication;
} hmdfc_image_info;

typedef struct hmdfc_section_info {
    const char * _Nonnull    segment_name;
    const char * _Nonnull    section_name;
    vm_address_t    addr;
    vm_size_t       size;
} hmdfc_section_info;

#pragma mark - section callback

typedef void (*HMDFC_image_query_enumerate_section_callback)(hmdfc_section_info * _Nonnull section, void * _Nonnull context);

typedef HMDFC_image_query_enumerate_section_callback HMDFC_section_callback;

#pragma mark - query function type

typedef bool (*HMDFC_image_query_begin)(uintptr_t address, void * _Nullable * _Nonnull image_identifier, hmdfc_image_info * _Nonnull macho_image_info);

typedef void (*HMDFC_image_query_enumerate_section)(void * _Nonnull async_macho_identifier,
                                                    HMDFC_section_callback _Nonnull callback,
                                                    void * _Nonnull context);

typedef void (*HMDFC_image_query_finish)(void * _Nonnull image_identifier);

#pragma mark - Extended Info

typedef struct hmdfc_image_identify_info {
    uuid_t UUID;
    const char * _Nullable path;
} hmdfc_image_identify_info;

#pragma mark - Image Callback

typedef void (*HMDFC_image_query_image_enumerate_callback)(hmdfc_image_info * _Nonnull macho_image_info,
                                                           hmdfc_image_identify_info * _Nonnull macho_image_identify_info,
                                                           void * _Nullable async_macho_identifier,
                                                           void * _Nullable context,
                                                           bool * _Nonnull stop);

typedef HMDFC_image_query_image_enumerate_callback HMDFC_image_enum_callback;

typedef void (*HMDFC_image_query_enumerate_image)(HMDFC_image_enum_callback _Nonnull callback,
                                                  void * _Nullable context);

#pragma mark - Image List Setup Status

typedef bool (*HMDFC_image_query_image_list_finished_setup)(void);

#pragma mark - namespace

typedef HMDFC_image_query_begin                     HMDFC_begin_func_t;
typedef HMDFC_image_query_enumerate_section         HMDFC_enum_section_func_t;
typedef HMDFC_image_query_finish                    HMDFC_finish_func_t;
typedef HMDFC_image_query_enumerate_image           HMDFC_enum_image_func_t;
typedef HMDFC_image_query_image_list_finished_setup HMDFC_list_finish_func_t;

#pragma mark - Deprecated

//typedef HMDFC_image_query_enumerate_section         HMDFC_enum_func_t;

HMDFC_EXTERN_SCOPE_END

#endif /* HMDFrameRecoverQuery_h */
