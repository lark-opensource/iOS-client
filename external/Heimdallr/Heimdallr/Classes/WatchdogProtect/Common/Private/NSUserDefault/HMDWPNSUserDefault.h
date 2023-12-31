//
//  HMDWPYYCache.h
//  AWECloudCommand
//
//  Created by 曾凯 on 2020/6/4.
//

#import <Foundation/Foundation.h>
#import "HMDWatchdogProtectDefine.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

extern void hmd_wp_toggle_nsuserdefault_protection(HMDWPExceptionCallback _Nullable callback);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
