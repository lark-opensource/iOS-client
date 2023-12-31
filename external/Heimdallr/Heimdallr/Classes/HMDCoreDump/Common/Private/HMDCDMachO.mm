//
//  HMDCDMachO.cpp
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/13.
//

#include "HMDCDMachO.hpp"
#include "HMDCDFile.hpp"
#include "HMDCrashSDKLog.h"


#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach-o/loader.h>

#define kTHREAD_COMMAND_SIZE 284

static bool isValidVM(unsigned int user_tag)
{
    if (user_tag == 0 ||
        user_tag == VM_MEMORY_MALLOC ||
        user_tag == VM_MEMORY_MALLOC_SMALL ||
        user_tag == VM_MEMORY_MALLOC_LARGE ||
        user_tag == VM_MEMORY_MALLOC_HUGE ||
        //VM_MEMORY_SBRK uninteresting -- no one should call
        user_tag == VM_MEMORY_REALLOC ||
        user_tag == VM_MEMORY_MALLOC_TINY ||
        user_tag == VM_MEMORY_MALLOC_LARGE_REUSABLE ||
        user_tag == VM_MEMORY_MALLOC_LARGE_REUSED ||
        //VM_MEMORY_ANALYSIS_TOOL
        user_tag == VM_MEMORY_MALLOC_NANO ||
//        user_tag == VM_MEMORY_MALLOC_MEDIUM ||
//        user_tag == VM_MEMORY_MALLOC_PGUARD ||
        user_tag == VM_MEMORY_MACH_MSG ||
        //VM_MEMORY_IOKIT
        user_tag == VM_MEMORY_STACK ||
        user_tag == VM_MEMORY_GUARD ||
        user_tag == VM_MEMORY_SHARED_PMAP ||
        user_tag == VM_MEMORY_DYLIB || /* memory containing a dylib */
        user_tag == VM_MEMORY_OBJC_DISPATCHERS ||
        user_tag == VM_MEMORY_UNSHARED_PMAP || /* Was a nested pmap (VM_MEMORY_SHARED_PMAP) which has now been unnested */
        user_tag == VM_MEMORY_DYLD || /* memory allocated by the dynamic loader for itself */
        user_tag == VM_MEMORY_DYLD_MALLOC || /* malloc'd memory created by dyld */
        user_tag == VM_MEMORY_OS_ALLOC_ONCE || /* libsystem_kernel os_once_alloc */
        user_tag == VM_MEMORY_LIBDISPATCH || /* libdispatch internal allocator */
        user_tag == VM_MEMORY_SWIFT_RUNTIME || /* Swift runtime */
        user_tag == VM_MEMORY_SWIFT_METADATA /* Swift metadata */
        ) {
        return true;
    }
    return false;
}

#ifdef __arm64__
static bool getMachineContext(thread_t thread, _STRUCT_MCONTEXT64 *machineContext)
{
    mach_msg_type_number_t state_count = ARM_THREAD_STATE64_COUNT;
    return KERN_SUCCESS == thread_get_state(thread, ARM_THREAD_STATE64, (thread_state_t
                                                                         )&machineContext->__ss, &state_count);
}
#endif

static bool writeThreadState(CDFile *file, thread_t thread, hmd_machine_context *crash_machine_ctx) {
#ifdef __arm64__
    _STRUCT_MCONTEXT64 machineContext;
    if (crash_machine_ctx && crash_machine_ctx->isCrashedContext) {
        //crash thread
        int common_num = hmdmc_num_registers();
        if (common_num != 34) return false;
        uintptr_t fp = hmdmc_register_value(crash_machine_ctx, 29);
        uintptr_t lr = hmdmc_register_value(crash_machine_ctx, 30);
        uintptr_t sp = hmdmc_register_value(crash_machine_ctx, 31);
        uintptr_t pc = hmdmc_register_value(crash_machine_ctx, 32);
        if (!(fp==0&&lr==0&&sp==0&&pc==0)) // can't get crash thread state (ps:nsexception cpp)
        {
            file->putHex32(LC_THREAD);
            file->putHex32(kTHREAD_COMMAND_SIZE);
            arm_state_hdr_t arm_state;
            arm_state.flavor = ARM_THREAD_STATE64;
            arm_state.count = ARM_THREAD_STATE64_COUNT;
            file->append(&arm_state, sizeof(arm_state_hdr_t));
            for(int index = 0; index < common_num; index++) {
                uintptr_t value = hmdmc_register_value(crash_machine_ctx, index);
                if (index == common_num -1) {
                    __uint32_t cpsr = (__uint32_t)value;
                    file->putHex32(cpsr);
                }
                else
                {
                    file->putHex64(value);
                }
            }
            return true;
        }
    }
    
    if (!getMachineContext(thread, &machineContext)) {
        SDKLog("coredump: get thread register fail");
        return false;
    }
    file->putHex32(LC_THREAD);
    file->putHex32(kTHREAD_COMMAND_SIZE);
    
    arm_state_hdr_t arm_state;
    arm_state.flavor = ARM_THREAD_STATE64;
    arm_state.count = ARM_THREAD_STATE64_COUNT;
    file->append(&arm_state, sizeof(arm_state_hdr_t));
    for (int i = 0; i < 29; i++)
    {
        file->putHex64(machineContext.__ss.__x[i]);
    }
    file->putHex64(machineContext.__ss.__fp);
    file->putHex64(machineContext.__ss.__lr);
    file->putHex64(machineContext.__ss.__sp);
    file->putHex64(machineContext.__ss.__pc);
    file->putHex32(machineContext.__ss.__cpsr);
#endif
    return true;
}

vm_size_t roundPageSize(vm_size_t size)
{
    if (size & 0x00000fff) {
        size += 0x00001000ull;
        size &= (~0x00001000ull + 1);
    }
    return size;
}

static int countOfVMRegion() {
    int count = 0;
    vm_address_t address = 0;
    vm_size_t size = 0;
    uint32_t nesting_depth = 0;
    kern_return_t    kret;
    struct vm_region_submap_info_64 info;
    
    while (true) {
        while (1) {
            mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
            kret = vm_region_recurse_64(mach_task_self(), &address, &size, &nesting_depth, (vm_region_info_64_t)&info, &count);
            if (kret == KERN_INVALID_ADDRESS){
                break;
            }
            if(info.is_submap) {
                nesting_depth++;
            } else {
                break;
            }
        }
        
        if((kret != KERN_SUCCESS) || (size == 0)) break;
        address += size;
        if (!isValidVM(info.user_tag) || (info.pages_resident == 0)) {
            continue;
        }
        
        vm_prot_t prot = info.protection;
        vm_prot_t maxprot = info.max_protection;
        if ((prot & VM_PROT_READ) == 0) {
            if (vm_protect(mach_task_self(), address, size, FALSE, prot|VM_PROT_READ)!= KERN_SUCCESS)
            {
                continue;
            }
        }
        if ((maxprot & VM_PROT_READ) == VM_PROT_READ//&& coredumpok(map,vmoffset)
            ) {
            count++;
        }
    }
    return count;
}


void writeResidentVM(CDFile *file, segment_command_64 sc64, int *ResidentCount, int maxPageCount, uintptr_t fault_addr) {
    vm_size_t vmpagesize = vm_kernel_page_size;
    vm_address_t address = sc64.vmaddr;
    int count = (int)(sc64.vmsize / vmpagesize);
    for (int i = 0; i < count; i++) {
        integer_t disposition = 0;
        integer_t ref_count = 0;
        vm_map_page_query(mach_task_self(), address, &disposition, &ref_count);
        if (disposition & VM_PAGE_QUERY_PAGE_DIRTY) {
            if (*ResidentCount < maxPageCount || (fault_addr>=address && fault_addr<address+vmpagesize)) {
                file->putHex64(address);
                file->append((const void *)address, vmpagesize);
                *ResidentCount = (*ResidentCount) + 1;
            }
        }
        address += vmpagesize;
    }
}

// promise device is iPhone, iOS10+, LP64 
bool saveCore(unsigned long fileSize, const char *path, struct hmd_crash_env_context *envContextPointer, double crashTime) {
    SDKLog("coredump: begin saveCore");
    if (path == NULL) {
        return false;
    }

    off_t foffset = 0;
    int regionCount = countOfVMRegion();
    if (regionCount < 1) {
        return false;
    }
    
    segment_command_64 *segment_load_commands = (segment_command_64 *)__builtin_alloca(regionCount * sizeof(segment_command_64));
    vm_address_t address = 0;
    vm_address_t currentAddress = 0;
    vm_size_t size = 0;
    uint32_t nesting_depth = 0;
    kern_return_t    kret;
    struct vm_region_submap_info_64 info;
    int index = 0;

    while (true) {
        while (1) {
            mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;
            kret = vm_region_recurse_64(mach_task_self(), &address, &size, &nesting_depth, (vm_region_info_64_t)&info, &count);
            if (kret == KERN_INVALID_ADDRESS){
                break;
            }
            if(info.is_submap) {
                nesting_depth++;
            } else {
                break;
            }
        }

        if((kret != KERN_SUCCESS) || size == 0 ) break;
        currentAddress = address;
        address += size;
        
        if (!isValidVM(info.user_tag) || (info.pages_resident == 0)) {
            continue;
        }
    
        vm_prot_t prot = info.protection;
        vm_prot_t maxprot = info.max_protection;

        if ((prot & VM_PROT_READ) == 0) {
            if (vm_protect(mach_task_self(), address, size, FALSE, prot|VM_PROT_READ)!= KERN_SUCCESS)
            {
                continue;
            }
        }

        if ((maxprot & VM_PROT_READ) == VM_PROT_READ//&& coredumpok(map,vmoffset)
            ) {
            if (index >= regionCount) {
                return false;
            }
            segment_command_64 sc64;
            sc64.cmd = LC_SEGMENT_64;
            sc64.cmdsize = sizeof(struct segment_command_64);
            sc64.segname[0] = 0;
            sc64.vmaddr = currentAddress;
            sc64.vmsize = size;
            sc64.fileoff = foffset;
            sc64.filesize = size;
            sc64.maxprot = maxprot;
            sc64.initprot = prot;
            sc64.nsects = 0;
            sc64.flags = 0;
            segment_load_commands[index++] = sc64;
            foffset += size;
        }
    }
    
    if (index != regionCount) {
        return false;
    }
    
    size_t segment_count = regionCount;
    int thread_count = envContextPointer->thread_count;
    size_t mach_header_sz = sizeof(struct mach_header_64);
    size_t segment_command_sz = sizeof(struct segment_command_64);
    size_t command_size = segment_count * segment_command_sz + thread_count * kTHREAD_COMMAND_SIZE;
    size_t header_size = mach_header_sz + command_size;
    header_size = roundPageSize(header_size);
    CDFile coreDumpFile = CDFile(path, fileSize);
    if (coreDumpFile.is_ok() == false) {
        return false;
    }
    
    struct mach_header_64    mh64;
    mh64.magic = MH_MAGIC_64;
    mh64.cputype = CPU_TYPE_ARM64;
    mh64.cpusubtype = CPU_SUBTYPE_ARM64_V8;
    mh64.filetype = MH_CORE;
    mh64.ncmds = (uint32_t)(thread_count + segment_count);
    mh64.sizeofcmds = (uint32_t)command_size;
    mh64.flags = 0;
    mh64.reserved = 0;        /* 8 byte alignment */
    
    // write flag
    coreDumpFile.setCursor(4);
    coreDumpFile.putHex32(1);  //version
    coreDumpFile.putHex64(0);  // file size
    coreDumpFile.putHex32(0);  //page count
    coreDumpFile.putHex64(crashTime); //crash time
    coreDumpFile.putHex32(0); //reserved
    
    // write header
    SDKLog("coredump: write header");
    coreDumpFile.append(&mh64, mach_header_sz);
    
    // crash thread
    thread_t crash_thread = THREAD_NULL;
    uintptr_t fault_addr = 0;
    hmd_machine_context *crash_machine_ctx = envContextPointer->crash_machine_ctx;
    if (crash_machine_ctx) {
        crash_thread = crash_machine_ctx->thread;
        fault_addr = crash_machine_ctx->fault_addr;
    }
    if (crash_thread == THREAD_NULL) {
        crash_thread = envContextPointer->current_thread;
    }
                                   
    // write thread command
    SDKLog("coredump: write thread command");
    for(mach_msg_type_number_t i = 0; i < envContextPointer->thread_count; i++)
    {
        thread_t thread = envContextPointer->thread_list[i];
        if (thread == crash_thread) {
            writeThreadState(&coreDumpFile, thread, crash_machine_ctx);
        }
        else
        {
            writeThreadState(&coreDumpFile, thread, NULL);
        }
    }
    
    // write segment command
    SDKLog("coredump: write segment command");
    for (int i = 0; i < segment_count; i++) {
        segment_command_64 sc64 = segment_load_commands[i];
        sc64.fileoff += header_size;
        coreDumpFile.append(&sc64, segment_command_sz);
    }
    
    // write vm
    SDKLog("coredump: write vm");
    int ResidentCount = 0;
    int maxPageCount = int(fileSize / vm_kernel_page_size);
    for (int i = 0; i < segment_count; i++) {
        segment_command_64 sc64 = segment_load_commands[i];
        writeResidentVM(&coreDumpFile, sc64, &ResidentCount, maxPageCount, fault_addr);
    }
    if (ResidentCount >= maxPageCount) {
        coreDumpFile.putHex32WithOffset(1, 28);
    }
    coreDumpFile.putHex32WithOffset(ResidentCount, 16);
    coreDumpFile.putHex32WithOffset(kCOREDUMPMAGIC, 0);
    coreDumpFile.end();
    SDKLog("coredump: end saveCore");
    return true;
}


