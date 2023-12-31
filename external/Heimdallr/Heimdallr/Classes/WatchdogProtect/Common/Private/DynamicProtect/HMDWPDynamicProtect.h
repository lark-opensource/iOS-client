//
//  HMDWPDynamicProtect.h
//  Heimdallr
//
//  Created by chengchao.cc on 2021/8/31.
//

#import <Foundation/Foundation.h>
#import "HMDWatchdogProtectDefine.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

extern void hmd_wp_toggle_dynamic_protection(NSArray<NSString *> *methodsOnlyMainThread,
                                             NSArray<NSString *> *methodsAnyThread,
                                             HMDWPExceptionCallback _Nullable callback);

extern NSSet<NSString *> *hmd_wp_dynamic_protect_method_set(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
