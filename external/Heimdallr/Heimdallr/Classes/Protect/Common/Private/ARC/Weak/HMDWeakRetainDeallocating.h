//
//  HMDWeakRetainDeallocating.h
//  Heimdallr
//
//  Created by bytedance on 2022/11/4.
//

#import <Foundation/Foundation.h>
#import "HMDProtect_Private.h"

NS_ASSUME_NONNULL_BEGIN

void HMD_Protect_toggle_weakRetainDeallocating_protection(HMDProtectCaptureBlock _Nullable captureBlock);

NS_ASSUME_NONNULL_END
