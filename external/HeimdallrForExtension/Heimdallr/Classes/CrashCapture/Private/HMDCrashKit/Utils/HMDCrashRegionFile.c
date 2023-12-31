//
//  HMDCrashRegionFile.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/14.
//

#include "HMDCrashRegionFile.h"
#include <dlfcn.h>
#include <stdatomic.h>
#include <unistd.h>
#include <string.h>

#define use_private_api 1

#if use_private_api
typedef int (*func)(int pid, uint64_t address, void * buffer, uint32_t buffersize);
static atomic_uintptr_t f;
#endif

void hmdcrash_init_filename(void) {
#if use_private_api
    if (atomic_load_explicit(&f,memory_order_acquire) > 0) {
        return;
    }
    char *ori_s = "bjfibknaihn`buXdhuw";
    size_t l = strlen(ori_s);
    char s[l+1];
    memset(s, 0, sizeof(s));
    for (int i = 0; i < l; i++) {
        s[i] = ori_s[l-i-1]^0x7;
    }
    void *ptr = dlsym(RTLD_NEXT, s);
    atomic_store_explicit(&f,(uintptr_t)ptr,memory_order_release);
#endif
}

int hmdcrash_filename(uint64_t address, void * buffer, uint32_t buffersize) {
#if use_private_api
    func ptr = (func)atomic_load_explicit(&f,memory_order_acquire);
    if (ptr == NULL) {
        return 0;
    }
    
    return ptr(getpid(),address,buffer,buffersize);
#else
    return 0;
#endif
}
