//
//  BDJSBridgeExecutorManager.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#import <Foundation/Foundation.h>
#import "BDJSBridgeExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDJSBridgeExecutorManager : NSObject<BDJSBridgeExecutor>

- (void)addExecutor:(id<BDJSBridgeExecutor>)executor;
- (id<BDJSBridgeExecutor>)executorForClass:(Class)clazz;

@end

NS_ASSUME_NONNULL_END
