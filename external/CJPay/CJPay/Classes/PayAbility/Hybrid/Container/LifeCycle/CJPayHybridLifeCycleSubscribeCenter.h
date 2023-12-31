//
//  CJPayHybridLifeCycleSubscribeCenter.h
//  cjpay_hybrid
//
//  Created by shanghuaijun on 2023/3/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HybridKitViewLifecycleProtocol;
@class CJPayTargetProxy;

@interface CJPayHybridLifeCycleSubscribeCenter : NSObject

@property (nonatomic, strong) CJPayTargetProxy<HybridKitViewLifecycleProtocol> *subscriberProxy;

+ (instancetype)defaultService;

- (void)addSubscriber:(id<HybridKitViewLifecycleProtocol>)subscriber;
- (void)removeSubscriber:(id)subscriber;

@end

NS_ASSUME_NONNULL_END
