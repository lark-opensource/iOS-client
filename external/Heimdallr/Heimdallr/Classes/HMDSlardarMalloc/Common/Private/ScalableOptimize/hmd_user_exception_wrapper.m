//
//  hmd_user_exception_wrapper.c
//  Heimdallr
//
//  Created by zhouyang11 on 2023/7/31.
//

#include "hmd_user_exception_wrapper.h"
#include "hmd_virtual_memory_macro.h"
#import "HMDDynamicCall.h"

void inline
hmd_slardar_malloc_trigger_user_exception_and_upload(const char* filter) {
#ifdef HMDBytestDefine
    NSString *filterStr = [NSString stringWithUTF8String:filter];
    id parameter = DC_CL(HMDUserExceptionParameter, initCurrentThreadParameterWithExceptionType:customParams:filters:, @"slardar_malloc_vm_user_exception", nil, @{@"type":filterStr?:@""});
    DC_OB(DC_CL(HMDUserExceptionTracker, sharedTracker), trackThreadLogWithParameter:callback:, parameter, ^(NSError * _Nullable error) {
        ff_printf("ff- user_exception upload %s\n", error?"fail":"success");
    });
#endif
}
