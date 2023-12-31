//
//  HMDGCD.h
//  Pods
//
//  Created by 白昆仑 on 2020/5/29.
//

#import <Foundation/Foundation.h>
#import "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

void hmd_safe_dispatch_async(dispatch_queue_t _Nullable queue, dispatch_block_t _Nullable block);

void hmd_safe_dispatch_after(dispatch_time_t when, dispatch_queue_t _Nullable queue, dispatch_block_t _Nullable block);

HMD_EXTERN_SCOPE_END
