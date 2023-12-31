//
//  JSWorkerBridgePool.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import <Foundation/Foundation.h>
#import "JSWorkerBridge.h"

NS_ASSUME_NONNULL_BEGIN

@interface JSWorkerBridgePool : NSObject

+ (JSWorkerBridge *_Nullable)bridgeForContainerID:(NSString *)containerID;

+ (void)registerBridge:(JSWorkerBridge*_Nullable)bridge forContainerID:(NSString *)containerID;
+ (void)unregisterBridgeForContainerID:(NSString *)containerID;

@end

NS_ASSUME_NONNULL_END
