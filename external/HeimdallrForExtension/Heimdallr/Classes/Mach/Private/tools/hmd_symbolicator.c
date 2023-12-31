//
//  hmd_symbolicator.c
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_symbolicator.h"
#include "HMDAsyncSymbolicator.h"
#include "HMDCompactUnwind.hpp"
#include "hmd_mach.h"

bool hmdsymbolicator_symbolicate(hmd_stack_cursor *cursor) {
    bool ret = false;
    uintptr_t address = CALL_INSTRUCTION_FROM_RETURN_ADDRESS(cursor->stackEntry.address);
    hmd_dl_info dl_info;
    memset(&dl_info, 0, sizeof(dl_info));
    ret = hmd_symbolicate(address, &dl_info, false);
    
    cursor->stackEntry.imageAddress = (uintptr_t)dl_info.dli_fbase;
    memcpy(cursor->stackEntry.imageName, dl_info.dli_fname, sizeof(cursor->stackEntry.imageName));
    cursor->stackEntry.imageName[sizeof(cursor->stackEntry.imageName)-1] = 0;
    
    cursor->stackEntry.symbolAddress = (uintptr_t)dl_info.dli_saddr;
    memcpy(cursor->stackEntry.symbolName, dl_info.dli_sname, sizeof(cursor->stackEntry.symbolName));
    cursor->stackEntry.symbolName[sizeof(cursor->stackEntry.symbolName)-1] = 0;

    return ret;
}

bool hmd_symbolicate(uintptr_t address, hmd_dl_info *info, bool need_symbol)
{
    if (info == NULL) {
        return false;
    }
    memset(info, 0, sizeof(*info));
    if (hmd_async_share_image_list_has_setup() == false) {
#ifdef DEBUG
        printf("shared image list is not ready now!"
               "please make sure setup finished before use it."
               "becuase hmd_setup_shared_image_list() is not async safe"
               "setup here a dead lock could happen");
        assert(0);
#endif
        Dl_info i = {0};
        bool r = hmd_dladdr(address, &i);
        hmd_dl_info_init(info, &i);
        return r;
    }
    bool ret = false;
    ret = hmd_async_dladdr(address, info, need_symbol);
    return ret;
}
