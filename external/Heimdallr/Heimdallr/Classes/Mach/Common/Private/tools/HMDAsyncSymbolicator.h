//
//  HMDAsyncSymbolicator.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/7/23.
//

#ifndef HMDAsyncSymbolicator_h
#define HMDAsyncSymbolicator_h

#include <stdint.h>
#include <dlfcn.h>

struct hmd_dl_info {
    char      dli_fname[512];     /* Pathname of shared object */
    void            *dli_fbase;     /* Base address of shared object */
    char      dli_sname[512];     /* Name of nearest symbol */
    void            *dli_saddr;     /* Address of nearest symbol */
};
typedef struct hmd_dl_info hmd_dl_info;

struct hmd_symbol_range {
    uintptr_t            dli_start_saddr;     /* Start address of nearest symbol */
    uintptr_t            dli_end_saddr;     /*End address of symbol */
};
typedef struct hmd_symbol_range hmd_symbol_range;

bool hmd_async_dladdr(const uintptr_t address, hmd_dl_info* const info, bool need_symbol);

bool hmd_symbol_address_range(const char *image_base_name,const char *symbol, hmd_symbol_range *range);

void hmd_dl_info_init(hmd_dl_info *target, Dl_info *info);

#endif /* HMDAsyncSymbolicator_h */
