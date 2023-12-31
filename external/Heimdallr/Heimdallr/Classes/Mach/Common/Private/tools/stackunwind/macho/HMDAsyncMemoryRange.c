//
//  HMDAsyncMemoryRange.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/2.
//

#include "HMDAsyncMemoryRange.h"

void * hmd_async_mem_range_pointer(hmd_async_mem_range range,hmd_vm_off_t offset,hmd_vm_size_t size)
{
    if (hmd_async_mem_range_verify_offset(range, range.addr, offset, size)) {
        return (void *)(range.addr + offset);
    }
    return NULL;
}

bool hmd_async_mem_range_verify(hmd_async_mem_range range,hmd_vm_address_t addr,hmd_vm_size_t size)
{
    return hmd_async_mem_range_verify_offset(range, addr, 0, size);
}

bool hmd_async_mem_range_verify_offset(hmd_async_mem_range range,hmd_vm_address_t addr,hmd_vm_off_t offset,hmd_vm_size_t size)
{
    /* Verify that the offset value won't overrun a native pointer */
    if (offset > 0 && UINTPTR_MAX - offset < addr) {
        return false;
    } else if (offset < 0 && (offset * -1) > addr) {
        return false;
    }

    /* Adjust the address using the verified offset */
    addr += offset;

    /* Verify that the address starts within range */
    if (addr < range.addr) {
        // HMDLOG_ERROR("Address %" PRIx64 " < base address %" PRIx64 "", (uint64_t) address, (uint64_t) mobj->address);
        return false;
    }

    /* Verify that the address value won't overrun */
    if (UINTPTR_MAX - size < addr) return false;

    /* Check that the block ends within range */
    if (range.addr + range.size < addr + size) {
        // HMDLOG_ERROR("Address %" PRIx64 " out of range %" PRIx64 " + %" PRIx64, (uint64_t) address, (uint64_t)
        // mobj->address, (uint64_t) mobj->length);
        return false;
    }

    return true;

}
