//
//  HMDVMRemapUtil.c
//  Heimdallr
//
//  Created by zhouyang11 on 2023/6/25.
//

#include "hmd_vm_remap_util.h"
#include <mach/vm_prot.h>
#include <mach/vm_map.h>
#include <mach/mach_init.h>
#include <mach/mach_port.h>
bool hmd_vm_remap_tmp(void* target_address, void* src_address, vm_size_t size) {
    vm_prot_t prot = VM_PROT_READ|VM_PROT_WRITE;
    vm_address_t currentAddress = (vm_address_t)target_address;
    int kr = vm_remap(mach_task_self(),
                      &currentAddress,
                      size,
                      0x0,
                      VM_FLAGS_FIXED|VM_FLAGS_OVERWRITE,
                      mach_task_self(),
                      (vm_address_t)src_address,
                      FALSE,
                      &prot,
                      &prot,
                      VM_INHERIT_NONE);
    
    if(kr != KERN_SUCCESS) {
        return false;
    }
    return true;
}

bool hmd_vm_remap(void* target_address, void* src_address, vm_size_t size) {
    
    /* the page we need to map */
    vm_address_t mapbase = mach_vm_trunc_page(src_address);
    vm_address_t mapSize = mach_vm_round_page(size + (src_address - mapbase));
    
    /* Initialize address is required, otherwise failed */
    vm_address_t storeAddress = (vm_address_t)target_address;
    
    /* what we need to do is: copy (mapBase, mapSize) into storeAddress  */
    vm_size_t copiedSize = 0;
    
    kern_return_t kr;
    
    while (copiedSize < mapSize) {
        
        memory_object_size_t entryLength = mapSize - copiedSize;
        mem_entry_name_port_t memoryObject;
        
        kr = mach_make_memory_entry_64(mach_task_self(),
                                       &entryLength,
                                       mapbase + copiedSize,
                                       VM_PROT_DEFAULT,
                                       &memoryObject,
                                       MACH_PORT_NULL);
        
        if(kr != KERN_SUCCESS) {
            break;  // exit while
        }
        
        vm_address_t currentAddress = storeAddress + copiedSize;
        
        kr = vm_map(mach_task_self(),
                    &currentAddress,
                    (vm_size_t)entryLength,
                    0x0,
                    VM_FLAGS_FIXED|VM_FLAGS_OVERWRITE,
                    memoryObject,
                    0x0,
                    FALSE,
                    VM_PROT_DEFAULT,
                    VM_PROT_DEFAULT,
                    VM_INHERIT_NONE);
        
        if (kr != KERN_SUCCESS) {
            break;
        }
        
        /* deference memory object */
        kr = mach_port_mod_refs(mach_task_self(), memoryObject, MACH_PORT_RIGHT_SEND, -1);
        
        /* if kr sucess and kr2 failed, free memory outside */
        if(kr != KERN_SUCCESS) {
            break;  // exit while
        }
        copiedSize += entryLength;
    }
    
    if(copiedSize >= mapSize) {
        return true;    // :>
    }
    return false;
}
