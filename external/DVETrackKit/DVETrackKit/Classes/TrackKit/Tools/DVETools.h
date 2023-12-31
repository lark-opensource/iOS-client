//
//  DVETools.h
//  NLEEditor
//
//  Created by bytedance on 2021/6/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN void dve_dispatch_queue_async_safe(dispatch_queue_t queue, dispatch_block_t block);

FOUNDATION_EXTERN void dve_dispatch_main_async_safe(dispatch_block_t block);

NS_ASSUME_NONNULL_END
