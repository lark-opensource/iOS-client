//
//  hmd_memory.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_memory.h"

#define HMDLogger_LocalLevel INFO

#include <mach/mach.h>

#import <errno.h>
#import <inttypes.h>
#import <stdint.h>
#import <string.h>
#include "hmd_logger.h"

/**
 * @internal
 * @defgroup hmd_async Async Safe Utilities
 * @ingroup hmd_internal
 *
 * Implements async-safe utility functions
 *
 * @{
 */

/* Simple byteswap wrappers */
static uint16_t hmd_swap16(uint16_t input) { return OSSwapInt16(input); }

static uint16_t hmd_nswap16(uint16_t input) { return input; }

static uint32_t hmd_swap32(uint32_t input) { return OSSwapInt32(input); }

static uint32_t hmd_nswap32(uint32_t input) { return input; }

static uint64_t hmd_swap64(uint64_t input) { return OSSwapInt64(input); }

static uint64_t hmd_nswap64(uint64_t input) { return input; }

/**
 * Byte swap functions for a target using the reverse of the host's byte order.
 */
const hmd_async_byteorder_t hmd_async_byteorder_swapped = {
    .swap16 = hmd_swap16, .swap32 = hmd_swap32, .swap64 = hmd_swap64};

/**
 * Byte swap functions for a target using the host's byte order. No swapping will be performed.
 */
const hmd_async_byteorder_t hmd_async_byteorder_direct = {
    .swap16 = hmd_nswap16, .swap32 = hmd_nswap32, .swap64 = hmd_nswap64};

/**
 * Return byte order functions that may be used to swap to/from little endian to host byte order.
 */
extern const hmd_async_byteorder_t *hmd_async_byteorder_little_endian(void) {
#if defined(__LITTLE_ENDIAN__)
    return &hmd_async_byteorder_direct;
#elif defined(__BIG_ENDIAN__)
    return &hmd_async_byteorder_swapped;
#else
#error Unknown byte order
#endif
}

/**
 * Return an error description for the given hmd_error_t.
 */
const char *hmd_async_strerror(hmd_error_t error) {
    switch (error) {
        case HMD_ESUCCESS:
            return "No error";
        case HMD_EUNKNOWN:
            return "Unknown error";
        case HMD_OUTPUT_ERR:
            return "Output file can not be opened (or written to)";
        case HMD_ENOMEM:
            return "No memory available";
        case HMD_ENOTSUP:
            return "Operation not supported";
        case HMD_EINVAL:
            return "Invalid argument";
        case HMD_EINTERNAL:
            return "Internal error";
        case HMD_EACCESS:
            return "Access denied";
        case HMD_ENOTFOUND:
            return "Not found";
        case HMD_EINVALID_DATA:
            return "The input data is in an unknown or invalid format.";
    }

    /* Should be unreachable */
    return "Unhandled error code";
}

hmd_error_t hmd_async_task_memcpy(mach_port_t task, hmd_vm_address_t address, hmd_vm_off_t offset, void *dest,
                                  hmd_vm_size_t len) {
    hmd_vm_address_t target;
    kern_return_t kt;

    /* Compute the target address and check for overflow */
    if (!hmd_async_address_apply_offset(address, offset, &target)) return HMD_ENOMEM;

    vm_size_t read_size = len;
    kt = vm_read_overwrite(task, target, len, (pointer_t)dest, &read_size);

    switch (kt) {
        case KERN_SUCCESS:
            return HMD_ESUCCESS;

        case KERN_INVALID_ADDRESS:
            return HMD_ENOTFOUND;
            break;

        case KERN_PROTECTION_FAILURE:
            return HMD_EACCESS;
            break;

        default:
            HMDLOG_ERROR("Unexpected error from vm_read_overwrite: %d", kt);
            return HMD_EUNKNOWN;
            break;
    }
}

/**
 * Safely add @a offset to @a base_address, returning the result in @a result. If an overflow would occur, false is
 * returned.
 *
 * @param base_address The base address from which @a result will be computed.
 * @param offset The offset to apply to @a base_address.
 * @param result The location in which to store the result.
 */
bool hmd_async_address_apply_offset(hmd_vm_address_t base_address, hmd_vm_off_t offset, hmd_vm_address_t *result) {
    /* Check for overflow */
    if (offset > 0 && HMD_VM_ADDRESS_MAX - offset < base_address) {
        return false;
    } else if (offset < 0 && (offset * -1) > base_address) {
        return false;
    }

    if (result != NULL) *result = base_address + offset;

    return true;
}

hmd_error_t hmd_async_read_string(hmd_vm_address_t address, void *dest, hmd_vm_size_t len)
{
    if (address == 0 || dest == NULL || len == 0 ) {
        return HMD_EINVAL;
    }
    char c = 0;
    hmd_vm_size_t offset = 0;
    hmd_error_t err = HMD_ESUCCESS;
    while (offset < len) {
        err = hmd_async_task_memcpy(current_task(), address + offset, 0, &c, 1);
        if (err != HMD_ESUCCESS) {
            break;
        }
        char *target = (char *)(dest + offset);
        *target = c;
        offset++;
        if (c == 0) {
            break;
        }
    }
    if (offset > 0) {
        //set last character 0
        char *target = (char *)(dest + len - 1);
        *target = 0;
        return HMD_ESUCCESS;
    }
    return err;
}

hmd_error_t hmd_async_read_memory(hmd_vm_address_t address, void *dest, hmd_vm_size_t len)
{
    return hmd_async_task_memcpy(current_task(), address, 0, dest, len);
}

/**
 * An intentionally naive async-safe implementation of strncmp(). strncmp() itself is not declared to be async-safe,
 * though in reality, it is.
 *
 * @param s1 First string.
 * @param s2 Second string.
 * @param n No more than n characters will be compared.
 * @return Return an integer greater than, equal to, or less than 0, according as the string @a s1 is greater than,
 * equal to, or less than the string @a s2.
 */
int hmd_async_strncmp(const char *s1, const char *s2, size_t n) {
    while (*s1 == *s2++ && n-- > 0) {
        if (*s1++ == 0) return (0);
    }

    if (n == 0) return 0;

    return (*(const unsigned char *)s1 - *(const unsigned char *)(s2 - 1));
}

/**
 * An intentionally naive async-safe implementation of memcpy(). memcpy() itself is not declared to be async-safe,
 * though in reality, it is.
 *
 * @param dest Destination.
 * @param source Source.
 * @param n Number of bytes to copy.
 */
void *hmd_async_memcpy(void *dest, const void *source, size_t n) {
    uint8_t *s = (uint8_t *)source;
    uint8_t *d = (uint8_t *)dest;

    for (size_t count = 0; count < n; count++) *d++ = *s++;

    return (void *)source;
}
