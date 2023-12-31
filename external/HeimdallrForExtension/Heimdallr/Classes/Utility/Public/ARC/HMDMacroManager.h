//
//  HMDMacroManager.h
//  Pods
//
//  Created by wangyinhui on 2022/5/30.
//

#ifndef HMDMacroManager_h
#define HMDMacroManager_h

#ifdef __cplusplus
extern "C" {
#endif

bool hmd_is_debug(void);

bool hmd_is_release(void);

bool hmd_is_inhouse(void);

bool hmd_is_address_sanitizer(void);

bool hmd_is_thread_sanitizer(void);

#ifdef __cplusplus
}
#endif


#endif /* HMDMacroManager_h */
