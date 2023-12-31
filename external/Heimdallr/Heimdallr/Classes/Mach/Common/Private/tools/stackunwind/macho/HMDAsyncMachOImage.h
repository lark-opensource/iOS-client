//
//  HMDAsyncMachOImage.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_ASYNC_MACHO_IMAGE_H
#define HMD_ASYNC_MACHO_IMAGE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach/mach.h>
#include <stdint.h>

#include "HMDAsyncMemoryRange.h"
#include "hmd_memory.h"
/**
 * @internal
 * @ingroup hmd_async_image
 * @{
 */

typedef struct hmd_async_segment {
    char seg_name[24];
    hmd_async_mem_range range;
    int32_t        maxprot;    /* maximum VM protection */
    int32_t        initprot;    /* initial VM protection */
} hmd_async_segment;

typedef struct hmd_async_section {
    char seg_name[24];
    char sec_name[24];
    hmd_async_mem_range range;
} hmd_async_section;

/**
 * @internal
 *
 * A Mach-O image instance.
 */
typedef struct hmd_async_macho {
    /** The binary image's header address. */
    hmd_vm_address_t header_addr;

    /** The binary's dyld-reported reported vmaddr slide. */
    hmd_vm_off_t vmaddr_slide;

    /** The binary image's name/path. */
    char *name;
    
    /** The binary image's uuid */
    char uuid[40];

    /** The Mach-O header. For our purposes, the 32-bit and 64-bit headers are identical. Note that the header
     * values may require byte-swapping for the local process' use. */
    struct mach_header header;

    /** Total size, in bytes, of the in-memory Mach-O header. This may differ from the header field above,
     * as the above field does not include the full mach_header_64 extensions to the mach_header. */
    hmd_vm_size_t header_size;

    /** Number of load commands */
    uint32_t ncmds;
    
    hmd_async_mem_range load_cmds;

    hmd_async_mem_range text_segment;
    
    hmd_async_mem_range unwind_info;
    
    hmd_async_mem_range crash_info;
    
    hmd_async_mem_range eh_frame;
    
    hmd_async_segment *segments;

    int segment_count;
    
    // ONLY support __PL64__
    hmd_async_section *interested_sections;
    int interested_sections_count;
    int interested_sections_allocated_count;
    
    uuid_t raw_uuid;
    
    /** If true, the image is 64-bit Mach-O. If false, it is a 32-bit Mach-O image. */
    bool m64;
    
    bool is_app_image;
    
    uint64_t entryOff;    /* file (__TEXT) offset of main() */

    /** The byte order functions to use for this image */
    const hmd_async_byteorder_t *byteorder;
} hmd_async_macho_t;

/**
 * @internal
 *
 * A mapped Mach-O segment.
 */
typedef struct hmd_async_macho_segment_t {
    /** The segment's mapped memory object */
    hmd_async_mem_range obj;

    /* File offset of this segment. */
    uint64_t fileoff;

    /* File size of the segment. */
    uint64_t filesize;
} hmd_async_macho_segment_t;

hmd_error_t hmd_nasync_macho_init(hmd_async_macho_t *image, const char *name, hmd_vm_address_t header);

cpu_type_t hmd_async_macho_cpu_type(hmd_async_macho_t *image);

cpu_subtype_t hmd_async_macho_cpu_subtype(hmd_async_macho_t *image);

bool hmd_async_macho_is_executable(hmd_async_macho_t *image);

bool hmd_async_macho_contains_address(hmd_async_macho_t *image, hmd_vm_address_t address);

void *hmd_async_macho_next_command(hmd_async_macho_t *image, void *previous);

void *hmd_async_macho_find_command(hmd_async_macho_t *image, uint32_t cmd);

hmd_error_t hmd_async_macho_find_segment(hmd_async_macho_t *image, const char *segname,
                                        hmd_async_macho_segment_t *seg);

hmd_async_macho_segment_t hmd_async_find_segment(hmd_async_macho_t *image, const char *segname);

void hmd_nasync_macho_free(hmd_async_macho_t *image);

/**
 * @}
 */

#ifdef __cplusplus
}
#endif

#endif /* HMD_ASYNC_MACHO_IMAGE_H */
