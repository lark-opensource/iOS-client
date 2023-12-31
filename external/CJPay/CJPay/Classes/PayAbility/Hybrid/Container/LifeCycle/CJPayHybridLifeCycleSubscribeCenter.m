//
//  CJPayHybridLifeCycleSubscribeCenter.m
//  cjpay_hybrid
//
//  Created by shanghuaijun on 2023/3/22.
//

#import "CJPayHybridLifeCycleSubscribeCenter.h"
#import "CJPayTargetProxy.h"
#import <HybridKit/HybridKitViewProtocol.h>

@interface CJPayHybridLifeCycleSubscribeCenter ()

@end

@implementation CJPayHybridLifeCycleSubscribeCenter

+ (instancetype)defaultService {
    static CJPayHybridLifeCycleSubscribeCenter *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayHybridLifeCycleSubscribeCenter alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _subscriberProxy = (CJPayTargetProxy<HybridKitViewLifecycleProtocol> *)[[CJPayTargetProxy alloc] init];
    }
    return self;
}

- (void)addSubscriber:(id<HybridKitViewLifecycleProtocol>)subscriber {
    [self.subscriberProxy addSubscriber:subscriber];
}

- (void)removeSubscriber:(id)subscriber {
    [self.subscriberProxy removeSubscriber:subscriber];
}


@end
