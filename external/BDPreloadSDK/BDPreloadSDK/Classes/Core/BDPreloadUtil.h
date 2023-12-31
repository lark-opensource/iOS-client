//
//  BDPreloadUtil.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/22.
//

#import <Foundation/Foundation.h>

#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BDPreloadUtil : NSObject

// 预加载任务调度队列
@property (nonatomic, strong, readonly, class) dispatch_queue_t preloadTaskQueue;

+ (BOOL)isWifiConnected;

+ (void)taskAsyncInPreloadQueue:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
