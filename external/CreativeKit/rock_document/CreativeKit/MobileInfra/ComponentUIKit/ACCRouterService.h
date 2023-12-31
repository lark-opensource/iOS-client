//
//  ACCRouterService.h
//  Indexer
//
//  Created by bytedance on 2021/9/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRouterServiceSubscriber;

@protocol ACCRouterService <NSObject>

- (void)addSubscriber:(id<ACCRouterServiceSubscriber>)subscriber;
- (void)removeSubscriber:(id<ACCRouterServiceSubscriber>)subscriber;

@end

@protocol ACCRouterServiceSubscriber <NSObject>

@optional

- (id)processedTargetVCInputDataFromData:(id)data;

@end

NS_ASSUME_NONNULL_END
