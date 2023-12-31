//
//  hmd_memory.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//
/* Utility functions for querying the mach kernel.
 */

#ifndef HDR_ksmemory_h
#define HDR_ksmemory_h
#include <stdbool.h>
#include "hmd_types.h"

#ifdef __cplusplus
extern "C" {
#endif

const char *hmd_async_strerror(hmd_error_t error);

bool hmd_async_address_apply_offset(hmd_vm_address_t base_address, hmd_vm_off_t offset, hmd_vm_address_t *result);

/**
 * @internal
 * @ingroup hmd_async
 *
 * Provides a set of byteswap functions that will swap from the target byte order to the host byte order.
 * This is used to provide byte order neutral polymorphism when parsing Mach-O and other file formats.
 */
typedef struct hmd_async_byteorder {
    /** The byte-swap function to use for 16-bit values. */
    uint16_t (*swap16)(uint16_t);

    /** The byte-swap function to use for 32-bit values. */
    uint32_t (*swap32)(uint32_t);

    /** The byte-swap function to use for 64-bit values. */
    uint64_t (*swap64)(uint64_t);

#ifdef __cplusplus
   public:
    /** Byte swap a 16-bit value */
    uint16_t swap(uint16_t v) const { return swap16(v); }

    /** Byte swap a 32-bit value */
    uint32_t swap(uint32_t v) const { return swap32(v); }

    /** Byte swap a 64-bit value */
    uint64_t swap(uint64_t v) const { return swap64(v); }
#endif
} hmd_async_byteorder_t;

extern const hmd_async_byteorder_t hmd_async_byteorder_swapped;
extern const hmd_async_byteorder_t hmd_async_byteorder_direct;

extern const hmd_async_byteorder_t *hmd_async_byteorder_little_endian(void);
//extern const hmd_async_byteorder_t *hmd_async_byteorder_big_endian(void);

hmd_error_t hmd_async_read_string(hmd_vm_address_t address, void *dest, hmd_vm_size_t len);

hmd_error_t hmd_async_read_memory(hmd_vm_address_t address, void *dest, hmd_vm_size_t len);

int hmd_async_strncmp(const char *s1, const char *s2, size_t n);
void *hmd_async_memcpy(void *dest, const void *source, size_t n);

#ifdef __cplusplus
}
#endif

#endif  // HDR_ksmemory_h
