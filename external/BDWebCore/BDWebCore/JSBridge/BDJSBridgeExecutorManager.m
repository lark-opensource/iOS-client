//
//  BDJSBridgeExecutorManager.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#import "BDJSBridgeExecutorManager.h"

@interface BDJSBridgeExecutorManager ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, id<BDJSBridgeExecutor>> *executors;
@property(nonatomic, strong) NSMutableArray<id<BDJSBridgeExecutor>> *sortedExecutors;

@end

@implementation BDJSBridgeExecutorManager

- (void)addExecutor:(id<BDJSBridgeExecutor>)executor {
    self.executors[NSStringFromClass(executor.class)] = executor;
    [self.sortedExecutors addObject:executor];
    self.sortedExecutors = [[self.sortedExecutors sortedArrayUsingComparator:^NSComparisonResult(id<BDJSBridgeExecutor>  _Nonnull obj1, id<BDJSBridgeExecutor>  _Nonnull obj2) {
        return obj1.priority <= obj2.priority ? NSOrderedDescending : NSOrderedAscending;
    }] mutableCopy];
}

- (id<BDJSBridgeExecutor>)executorForClass:(Class)clazz {
    return self.executors[NSStringFromClass(clazz)];
}

- (NSMutableDictionary<NSString *, id<BDJSBridgeExecutor>> *)executors {
    if (!_executors) {
        _executors = NSMutableDictionary.dictionary;
    }
    return _executors;
}

- (NSMutableArray<id<BDJSBridgeExecutor>> *)sortedExecutors {
    if (!_sortedExecutors) {
        _sortedExecutors = NSMutableArray.array;
    }
    return _sortedExecutors;
}

- (BDJSBridgeExecutorFlowShouldContinue)invokeBridgeWithMessage:(BDJSBridgeMessage *)message callback:(nonnull BDJSBridgeCallback)callback isForced:(BOOL)isForced{
    __block __auto_type shouldContinue = YES;
    [self.sortedExecutors enumerateObjectsUsingBlock:^(id<BDJSBridgeExecutor>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:_cmd]) {
            shouldContinue = [obj invokeBridgeWithMessage:message callback:callback isForced:isForced];
            if (!shouldContinue) {
                *stop = YES;
            }
        }
    }];
    if (shouldContinue) {
        callback(BDJSBridgeStatusNoHandler, nil, nil);
    }
    return shouldContinue;
}

- (BDJSBridgeExecutorFlowShouldContinue)willCallbackBridgeWithMessage:(BDJSBridgeMessage *)message callback:(nonnull BDJSBridgeCallback)callback{
    __block __auto_type shouldContinue = YES;
    [self.executors enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<BDJSBridgeExecutor>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:_cmd]) {
            shouldContinue = [obj willCallbackBridgeWithMessage:message callback:callback];
            if (!shouldContinue) {
                *stop = YES;
            }
        }
    }];
    return shouldContinue;
}


@end
