//
//  SGMNetworkAPIClient.h
//  LiveStreaming
//
//  Created by renfeng.zhang on 2017/9/8.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SGMNetworkCompletionBlock)(NSError *error, id response);
//typedef void(^SGMNetworkCompletionBlock)(NSError *error, NSDictionary *response);

@interface SGMNetworkAPIClient : NSObject

/* 回调是异步的，不在主线程执行 */
+ (void)SGM_POST:(NSString *)URLString URLParameters:(NSDictionary *)URLParameters bodyParameters:(NSDictionary *)bodyParameters completion:(SGMNetworkCompletionBlock)completion;

/* 同步操作，小心死锁 */
+ (void)SGM_POST_SYNC:(NSString *)URLString URLParameters:(NSDictionary *)URLParameters bodyParameters:(NSDictionary *)bodyParameters completion:(SGMNetworkCompletionBlock)completion;

/* 回调是异步的，不在主线程执行 */
+ (void)SGM_GET:(NSString *)URLString parameters:(NSDictionary *)parameters completion:(SGMNetworkCompletionBlock)completion;

@end //HTSDataAcquisitionNetworkAPIClient
