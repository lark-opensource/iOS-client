//
//  HMDMacroManager.h
//  Pods
//
//  Created by wangyinhui on 2022/5/30.
//

#ifndef HMDMacroManager_h
#define HMDMacroManager_h

#import "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

bool hmd_is_debug(void);

bool hmd_is_release(void);

bool hmd_is_inhouse(void);

bool hmd_is_address_sanitizer(void);

bool hmd_is_thread_sanitizer(void);

#define HMD_IS_DEBUG hmd_is_debug()
#define HMD_IS_RELEASE hmd_is_release()
#define HMD_IS_INHOUSE hmd_is_inhouse()
#define HMD_IS_ADDRESS_SANITIZER hmd_is_address_sanitizer()
#define HMD_IS_THREAD_SANITIZER hmd_is_thread_sanitizer()

HMD_EXTERN_SCOPE_END

#endif /* HMDMacroManager_h */
