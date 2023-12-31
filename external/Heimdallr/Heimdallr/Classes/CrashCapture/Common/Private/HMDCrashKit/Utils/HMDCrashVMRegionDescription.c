//
//  HMDCrashVMRegionDescription.c
//  AWECloudCommand-iOS13.0
//
//  Created by yuanzhangjing on 2019/12/1.
//

#include "HMDCrashVMRegionDescription.h"

#define macro_case(a) \
case a: \
ret = #a; \
    break; \

const char *hmd_vm_region_user_tag_string(unsigned int user_tag) {
    const char *ret = NULL;
    switch (user_tag) {
            macro_case(VM_MEMORY_MALLOC)
            macro_case(VM_MEMORY_MALLOC_SMALL)
            macro_case(VM_MEMORY_MALLOC_LARGE)
            macro_case(VM_MEMORY_MALLOC_HUGE)
            macro_case(VM_MEMORY_SBRK)
            macro_case(VM_MEMORY_REALLOC)
            macro_case(VM_MEMORY_MALLOC_TINY)
            macro_case(VM_MEMORY_MALLOC_LARGE_REUSABLE)
            macro_case(VM_MEMORY_MALLOC_LARGE_REUSED)
            macro_case(VM_MEMORY_ANALYSIS_TOOL)
            macro_case(VM_MEMORY_MALLOC_NANO)
#ifdef VM_MEMORY_MALLOC_MEDIUM
            macro_case(VM_MEMORY_MALLOC_MEDIUM)
#endif
            macro_case(VM_MEMORY_MACH_MSG)
            macro_case(VM_MEMORY_IOKIT)
            macro_case(VM_MEMORY_STACK)
            macro_case(VM_MEMORY_GUARD)
            macro_case(VM_MEMORY_SHARED_PMAP)
            macro_case(VM_MEMORY_DYLIB)
            macro_case(VM_MEMORY_OBJC_DISPATCHERS)
            macro_case(VM_MEMORY_UNSHARED_PMAP)
            macro_case(VM_MEMORY_APPKIT)
            macro_case(VM_MEMORY_FOUNDATION)
            macro_case(VM_MEMORY_COREGRAPHICS)
            macro_case(VM_MEMORY_CORESERVICES)
            macro_case(VM_MEMORY_JAVA)
            macro_case(VM_MEMORY_COREDATA)
            macro_case(VM_MEMORY_COREDATA_OBJECTIDS)
            macro_case(VM_MEMORY_ATS)
            macro_case(VM_MEMORY_LAYERKIT)
            macro_case(VM_MEMORY_CGIMAGE)
            macro_case(VM_MEMORY_TCMALLOC)
            macro_case(VM_MEMORY_COREGRAPHICS_DATA)
            macro_case(VM_MEMORY_COREGRAPHICS_SHARED)
            macro_case(VM_MEMORY_COREGRAPHICS_FRAMEBUFFERS)
            macro_case(VM_MEMORY_COREGRAPHICS_BACKINGSTORES)
            macro_case(VM_MEMORY_COREGRAPHICS_XALLOC)
            macro_case(VM_MEMORY_DYLD)
            macro_case(VM_MEMORY_DYLD_MALLOC)
            macro_case(VM_MEMORY_SQLITE)
            macro_case(VM_MEMORY_JAVASCRIPT_CORE)
            macro_case(VM_MEMORY_JAVASCRIPT_JIT_EXECUTABLE_ALLOCATOR)
            macro_case(VM_MEMORY_JAVASCRIPT_JIT_REGISTER_FILE)
            macro_case(VM_MEMORY_GLSL)
            macro_case(VM_MEMORY_OPENCL)
            macro_case(VM_MEMORY_COREIMAGE)
            macro_case(VM_MEMORY_WEBCORE_PURGEABLE_BUFFERS)
            macro_case(VM_MEMORY_IMAGEIO)
            macro_case(VM_MEMORY_COREPROFILE)
            macro_case(VM_MEMORY_ASSETSD)
            macro_case(VM_MEMORY_OS_ALLOC_ONCE)
            macro_case(VM_MEMORY_LIBDISPATCH)
            macro_case(VM_MEMORY_ACCELERATE)
            macro_case(VM_MEMORY_COREUI)
            macro_case(VM_MEMORY_COREUIFILE)
            macro_case(VM_MEMORY_GENEALOGY)
            macro_case(VM_MEMORY_RAWCAMERA)
            macro_case(VM_MEMORY_CORPSEINFO)
            macro_case(VM_MEMORY_SWIFT_RUNTIME)
            macro_case(VM_MEMORY_SWIFT_METADATA)
            macro_case(VM_MEMORY_DHMM)
            macro_case(VM_MEMORY_SCENEKIT)
            macro_case(VM_MEMORY_SKYWALK)
            macro_case(VM_MEMORY_IOSURFACE)
            macro_case(VM_MEMORY_LIBNETWORK)
            macro_case(VM_MEMORY_AUDIO)
            macro_case(VM_MEMORY_VIDEOBITSTREAM)
            macro_case(VM_MEMORY_CM_XPC)
            macro_case(VM_MEMORY_CM_RPC)
            macro_case(VM_MEMORY_CM_MEMORYPOOL)
            macro_case(VM_MEMORY_CM_READCACHE)
            macro_case(VM_MEMORY_CM_CRABS)
            macro_case(VM_MEMORY_QUICKLOOK_THUMBNAILS)
            macro_case(VM_MEMORY_ACCOUNTS)
#ifdef VM_MEMORY_SANITIZER
            macro_case(VM_MEMORY_SANITIZER)
#endif
#ifdef VM_MEMORY_IOACCELERATOR
            macro_case(VM_MEMORY_IOACCELERATOR)
#endif
#ifdef VM_MEMORY_CM_REGWARP
            macro_case(VM_MEMORY_CM_REGWARP)
#endif
        default:
            break;
    }
    return ret;
}

const char *hmd_vm_region_share_mode_string(unsigned int share_mode) {
    const char *ret = NULL;
    switch (share_mode) {
            macro_case(SM_COW)
            macro_case(SM_PRIVATE)
            macro_case(SM_EMPTY)
            macro_case(SM_SHARED)
            macro_case(SM_TRUESHARED)
            macro_case(SM_PRIVATE_ALIASED)
            macro_case(SM_SHARED_ALIASED)
            macro_case(SM_LARGE_PAGE)
        default:
            break;
    }
    return ret;
}
