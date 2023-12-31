//
//   DVEGCDUtils.h
//   DVEFoundationKit
//
//   Created  by ByteDance on 2021/12/15.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN void dve_dispatch_queue_async_safe(dispatch_queue_t queue, dispatch_block_t block);

FOUNDATION_EXTERN void dve_dispatch_main_async_safe(dispatch_block_t block);

FOUNDATION_EXTERN void dve_dispatch_main_thread_async_safe(dispatch_block_t block);

NS_ASSUME_NONNULL_END
