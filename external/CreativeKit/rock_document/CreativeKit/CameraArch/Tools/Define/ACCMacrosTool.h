//
//  ACCMacrosTool.h
//  CreativeKit-Pods-Aweme
//
//  Created by lixingdong on 2021/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN void acc_dispatch_queue_async_safe(dispatch_queue_t queue, dispatch_block_t block);

FOUNDATION_EXTERN void acc_dispatch_main_async_safe(dispatch_block_t block);

FOUNDATION_EXPORT void acc_dispatch_main_thread_async_safe(dispatch_block_t block);

NS_ASSUME_NONNULL_END

FOUNDATION_EXTERN BOOL ACC_isEmptyString(NSString *param);

FOUNDATION_EXTERN BOOL ACC_isEmptyArray(NSArray *param);

FOUNDATION_EXTERN BOOL ACC_isEmptyDictionary(NSDictionary *param);
