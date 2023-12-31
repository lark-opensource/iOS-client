//
//  HMDCrashRegionFile.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/14.
//

#include <dlfcn.h>
#include <unistd.h>
#include <string.h>
#include <stdatomic.h>

#include "HMDMacro.h"
#include "HMDCrashRegionFile.h"


typedef int (*func)(int pid, uint64_t address, void * buffer, uint32_t buffersize);
//static atomic_uintptr_t flag;

#pragma mark - !HMD_APPSTORE_REVIEW_FIXUP
#if !HMD_APPSTORE_REVIEW_FIXUP

//void hmdcrash_init_filename(void) {
//    if (atomic_load_explicit(&flag, memory_order_acquire) > 0) {
//        return;
//    }
//    char *ori_s = "bjfibknaihn`buXdhuw";
//    size_t l = strlen(ori_s);
//    char s[l+1];
//    memset(s, 0, sizeof(s));
//    for (int i = 0; i < l; i++) {
//        s[i] = ori_s[l-i-1]^0x7;
//    }
//    void *ptr = dlsym(RTLD_NEXT, s);
//    atomic_store_explicit(&flag,(uintptr_t)ptr, memory_order_release);
//}
//
//int hmdcrash_filename(uint64_t address, void * buffer, uint32_t buffersize) {
//    func ptr = (func)atomic_load_explicit(&flag, memory_order_acquire);
//    if (ptr == NULL) {
//        return 0;
//    }
//    return ptr(getpid(),address,buffer,buffersize);
//}

#pragma mark - HMD_APPSTORE_REVIEW_FIXUP
#else   /* !HMD_APPSTORE_REVIEW_FIXUP */

void hmdcrash_init_filename(void) {
    
}

int hmdcrash_filename(uint64_t address, void * buffer, uint32_t buffersize) {
    return 0;
}

#endif /* !HMD_APPSTORE_REVIEW_FIXUP */
