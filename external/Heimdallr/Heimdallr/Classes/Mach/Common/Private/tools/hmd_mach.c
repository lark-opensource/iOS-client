//
//  hmd_mach.c
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/2/23.
//

#include <stdlib.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include "hmd_mach.h"
#include "HMDMacro.h"

#define RETURN_NAME_FOR_ENUM(A) \
    case A:                     \
        return #A

const char *hmdmach_exceptionName(const int64_t exceptionType) {
    switch (exceptionType) {
        RETURN_NAME_FOR_ENUM(EXC_BAD_ACCESS);
        RETURN_NAME_FOR_ENUM(EXC_BAD_INSTRUCTION);
        RETURN_NAME_FOR_ENUM(EXC_ARITHMETIC);
        RETURN_NAME_FOR_ENUM(EXC_EMULATION);
        RETURN_NAME_FOR_ENUM(EXC_SOFTWARE);
        RETURN_NAME_FOR_ENUM(EXC_BREAKPOINT);
        RETURN_NAME_FOR_ENUM(EXC_SYSCALL);
        RETURN_NAME_FOR_ENUM(EXC_MACH_SYSCALL);
        RETURN_NAME_FOR_ENUM(EXC_RPC_ALERT);
        RETURN_NAME_FOR_ENUM(EXC_CRASH);
    }
    return NULL;
}

const char *hmdmach_kernelReturnCodeName(const int64_t returnCode) {
    switch (returnCode) {
        RETURN_NAME_FOR_ENUM(KERN_SUCCESS);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_ADDRESS);
        RETURN_NAME_FOR_ENUM(KERN_PROTECTION_FAILURE);
        RETURN_NAME_FOR_ENUM(KERN_NO_SPACE);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_ARGUMENT);
        RETURN_NAME_FOR_ENUM(KERN_FAILURE);
        RETURN_NAME_FOR_ENUM(KERN_RESOURCE_SHORTAGE);
        RETURN_NAME_FOR_ENUM(KERN_NOT_RECEIVER);
        RETURN_NAME_FOR_ENUM(KERN_NO_ACCESS);
        RETURN_NAME_FOR_ENUM(KERN_MEMORY_FAILURE);
        RETURN_NAME_FOR_ENUM(KERN_MEMORY_ERROR);
        RETURN_NAME_FOR_ENUM(KERN_ALREADY_IN_SET);
        RETURN_NAME_FOR_ENUM(KERN_NOT_IN_SET);
        RETURN_NAME_FOR_ENUM(KERN_NAME_EXISTS);
        RETURN_NAME_FOR_ENUM(KERN_ABORTED);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_NAME);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_TASK);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_RIGHT);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_VALUE);
        RETURN_NAME_FOR_ENUM(KERN_UREFS_OVERFLOW);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_CAPABILITY);
        RETURN_NAME_FOR_ENUM(KERN_RIGHT_EXISTS);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_HOST);
        RETURN_NAME_FOR_ENUM(KERN_MEMORY_PRESENT);
        RETURN_NAME_FOR_ENUM(KERN_MEMORY_DATA_MOVED);
        RETURN_NAME_FOR_ENUM(KERN_MEMORY_RESTART_COPY);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_PROCESSOR_SET);
        RETURN_NAME_FOR_ENUM(KERN_POLICY_LIMIT);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_POLICY);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_OBJECT);
        RETURN_NAME_FOR_ENUM(KERN_ALREADY_WAITING);
        RETURN_NAME_FOR_ENUM(KERN_DEFAULT_SET);
        RETURN_NAME_FOR_ENUM(KERN_EXCEPTION_PROTECTED);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_LEDGER);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_MEMORY_CONTROL);
        RETURN_NAME_FOR_ENUM(KERN_INVALID_SECURITY);
        RETURN_NAME_FOR_ENUM(KERN_NOT_DEPRESSED);
        RETURN_NAME_FOR_ENUM(KERN_TERMINATED);
        RETURN_NAME_FOR_ENUM(KERN_LOCK_SET_DESTROYED);
        RETURN_NAME_FOR_ENUM(KERN_LOCK_UNSTABLE);
        RETURN_NAME_FOR_ENUM(KERN_LOCK_OWNED);
        RETURN_NAME_FOR_ENUM(KERN_LOCK_OWNED_SELF);
        RETURN_NAME_FOR_ENUM(KERN_SEMAPHORE_DESTROYED);
        RETURN_NAME_FOR_ENUM(KERN_RPC_SERVER_TERMINATED);
        RETURN_NAME_FOR_ENUM(KERN_RPC_TERMINATE_ORPHAN);
        RETURN_NAME_FOR_ENUM(KERN_RPC_CONTINUE_ORPHAN);
        RETURN_NAME_FOR_ENUM(KERN_NOT_SUPPORTED);
        RETURN_NAME_FOR_ENUM(KERN_NODE_DOWN);
        RETURN_NAME_FOR_ENUM(KERN_NOT_WAITING);
        RETURN_NAME_FOR_ENUM(KERN_OPERATION_TIMED_OUT);
        RETURN_NAME_FOR_ENUM(KERN_CODESIGN_ERROR);
    }
    return NULL;
}

const char* hmdmach_codeName(int64_t exceptionType, int64_t code) {
#if   defined (__arm__) || defined (__arm64__)
    switch (exceptionType) {
        case EXC_BAD_INSTRUCTION:
        {
            switch (code) {
                    RETURN_NAME_FOR_ENUM(EXC_ARM_UNDEFINED);
            }
            break;
        }
        case EXC_BAD_ACCESS:
        {
            const char *ret = hmdmach_kernelReturnCodeName((int64_t)code);
            if (ret) {
                return ret;
            }
            switch (code) {
                    RETURN_NAME_FOR_ENUM(EXC_ARM_DA_ALIGN);
                    RETURN_NAME_FOR_ENUM(EXC_ARM_DA_DEBUG);
                    RETURN_NAME_FOR_ENUM(EXC_ARM_SP_ALIGN);
                    RETURN_NAME_FOR_ENUM(EXC_ARM_SWP);
            }
            break;
        }
        case EXC_ARITHMETIC:
        {
            switch (code) {
#ifdef EXC_ARM_FP_UNDEFINED
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_UNDEFINED);
#endif
#ifdef EXC_ARM_FP_IO
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_IO);
#endif
#ifdef EXC_ARM_FP_DZ
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_DZ);
#endif
#ifdef EXC_ARM_FP_OF
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_OF);
#endif
#ifdef EXC_ARM_FP_UF
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_UF);
#endif
#ifdef EXC_ARM_FP_IX
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_IX);
#endif
#ifdef EXC_ARM_FP_ID
                    RETURN_NAME_FOR_ENUM(EXC_ARM_FP_ID);
#endif
            }
            break;
        }
        case EXC_BREAKPOINT:
        {
            switch (code) {
                    RETURN_NAME_FOR_ENUM(EXC_ARM_BREAKPOINT);
            }
            break;
        }
            
        default:
            break;
    }
#else
    if (exceptionType == EXC_BAD_ACCESS) {
        const char *ret = hmdmach_kernelReturnCodeName((int64_t)code);
        if (ret) {
            return ret;
        }
    }
#endif

    return NULL;
}

#define EXC_UNIX_BAD_SYSCALL 0x10000 /* SIGSYS */
#define EXC_UNIX_BAD_PIPE 0x10001    /* SIGPIPE */
#define EXC_UNIX_ABORT 0x10002       /* SIGABRT */

int hmdmach_machExceptionForSignal(const int sigNum) {
    switch (sigNum) {
        case SIGFPE:
            return EXC_ARITHMETIC;
        case SIGSEGV:
            return EXC_BAD_ACCESS;
        case SIGBUS:
            return EXC_BAD_ACCESS;
        case SIGILL:
            return EXC_BAD_INSTRUCTION;
        case SIGTRAP:
            return EXC_BREAKPOINT;
        case SIGEMT:
            return EXC_EMULATION;
        case SIGSYS:
            return EXC_UNIX_BAD_SYSCALL;
        case SIGPIPE:
            return EXC_UNIX_BAD_PIPE;
        case SIGABRT:
            // The Apple reporter uses EXC_CRASH instead of EXC_UNIX_ABORT
            return EXC_CRASH;
        case SIGKILL:
            return EXC_SOFT_SIGNAL;
    }
    return 0;
}

int hmdmach_signalForMachException(const int exception, const mach_exception_code_t code) {
    switch (exception) {
        case EXC_ARITHMETIC:
            return SIGFPE;
        case EXC_BAD_ACCESS:
            return code == KERN_INVALID_ADDRESS ? SIGSEGV : SIGBUS;
        case EXC_BAD_INSTRUCTION:
            return SIGILL;
        case EXC_BREAKPOINT:
            return SIGTRAP;
        case EXC_EMULATION:
            return SIGEMT;
        case EXC_SOFTWARE: {
            switch (code) {
                case EXC_UNIX_BAD_SYSCALL:
                    return SIGSYS;
                case EXC_UNIX_BAD_PIPE:
                    return SIGPIPE;
                case EXC_UNIX_ABORT:
                    return SIGABRT;
                case EXC_SOFT_SIGNAL:
                    return SIGKILL;
            }
            break;
        }
    }
    return 0;
}


//hmd_dladdr
static uintptr_t firstCmdAfterHeader(const struct mach_header* const header) {
    switch (header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            // Header is corrupt
            return 0;
    }
}

static uint32_t imageIndexContainingAddress(const uintptr_t address) {
    const uint32_t imageCount = _dyld_image_count();
    const struct mach_header* header = 0;
    
    for (uint32_t iImg = 0; iImg < imageCount; iImg++) {
        header = _dyld_get_image_header(iImg);
        if (header != NULL) {
            // Look for a segment command with this address within its range.
            uintptr_t addressWSlide = address - (uintptr_t)_dyld_get_image_vmaddr_slide(iImg);
            uintptr_t cmdPtr = firstCmdAfterHeader(header);
            if (cmdPtr == 0) {
                continue;
            }
            for (uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
                const struct load_command* loadCmd = (struct load_command*)cmdPtr;
                if (loadCmd->cmd == LC_SEGMENT) {
                const struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                    if (addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                } else if (loadCmd->cmd == LC_SEGMENT_64) {
                    const struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                    if (addressWSlide >= segCmd->vmaddr && addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                }
                cmdPtr += loadCmd->cmdsize;
            }
        }
    }
    return UINT32_MAX;
}

bool hmd_dladdr(const uintptr_t address, Dl_info* const info) {
    info->dli_fname = NULL;
    info->dli_fbase = NULL;
    info->dli_sname = NULL;
    info->dli_saddr = NULL;
    
    const uint32_t idx = imageIndexContainingAddress(address);
    if (idx == UINT32_MAX) {
        return false;
    }
    const struct mach_header* header = _dyld_get_image_header(idx);
    info->dli_fname = _dyld_get_image_name(idx);
    info->dli_fbase = (void*)header;
    
    return true;
}

bool hmd_vm_region_query_basic_info(void * _Nullable * _Nonnull address, vm_size_t * _Nullable size, hmd_vm_region_basic_info_t _Nonnull info) {
    if(address == NULL || info == NULL) DEBUG_RETURN(false);
    
    vm_address_t fromAddress = (vm_address_t)address[0];
    vm_size_t querySize = 0x0;
    
#ifdef __LP64__
    struct vm_region_basic_info_64 queryInfo;
    mach_msg_type_number_t infoCount = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t memory_object = MACH_PORT_NULL;
    
    kern_return_t kr = vm_region_64(mach_task_self(),
                                    &fromAddress,
                                    &querySize,
                                    VM_REGION_BASIC_INFO_64,
                                    (vm_region_info_t)&queryInfo,
                                    &infoCount,
                                    &memory_object);
#else
    struct vm_region_basic_info queryInfo;
    mach_msg_type_number_t infoCount = VM_REGION_BASIC_INFO_COUNT;
    mach_port_t memory_object = MACH_PORT_NULL;
    
    kern_return_t kr = vm_region(mach_task_self(),
                                 &fromAddress,
                                 &querySize,
                                 VM_REGION_BASIC_INFO,
                                 (vm_region_info_t)&queryInfo,
                                 &infoCount,
                                 &memory_object);
#endif
    CLANG_DIAGNOSTIC_PUSH
    CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
    kern_return_t kr2 = mach_port_deallocate(mach_task_self(), memory_object);
    CLANG_DIAGNOSTIC_POP
    DEBUG_ASSERT(kr2 == KERN_SUCCESS);
    if(kr == KERN_SUCCESS) {
        address[0] = (void *)fromAddress;
        if(size != NULL) size[0] = querySize;
        info[0] = queryInfo;
        return true;
    }
    else return false;
}
